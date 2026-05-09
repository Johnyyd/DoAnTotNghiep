using GMP_System.Entities;
using Serilog;
using Prometheus;
using GMP_System.Interfaces;
using GMP_System.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading;
using System.Linq;
using System.Collections.Generic;
using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);

// ------------------------------------------------------------
// 0. LOGGING: Serilog configuration (JSON to console & file)
// ------------------------------------------------------------
builder.Host.UseSerilog((context, services, configuration) =>
    configuration
        .Enrich.FromLogContext()
        .WriteTo.Console()
        .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day)
    );

// ============================================================
// 4. AUTHORIZATION: RBAC Policies
// ============================================================
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAdmin", policy => policy.RequireClaim("role", "Admin"));
    options.AddPolicy("RequireQC", policy => policy.RequireClaim("role", "QC"));
    options.AddPolicy("RequireOperator", policy => policy.RequireClaim("role", "Operator"));
});

// ============================================================
// 1. CONTROLLERS + JSON
// ============================================================
builder.Services.AddControllers(options =>
{
    options.Filters.Add(new AuthorizeFilter());
}).AddJsonOptions(x =>
{
    x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ============================================================
// 3. DATABASE: SQL SERVER
// ============================================================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
                    ?? builder.Configuration["SQL_CONNECTION_STRING"]
                    ?? builder.Configuration["DATABASE_URL"];

// Mask connection string for security while logging
string maskedConn = connectionString != null 
    ? System.Text.RegularExpressions.Regex.Replace(connectionString, @"Password=[^;]+", "Password=****")
    : "NULL";

Console.WriteLine($"[BACKEND] Starting with Connection String: {maskedConn}");

builder.Services.AddDbContext<GmpContext>(options =>
    options.UseSqlServer(connectionString));

builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// ============================================================
// 5. SECURITY: CORS + JWT
// ============================================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowVercelAndLocal",
        policy =>
        {
            policy.SetIsOriginAllowed(origin => 
                    new Uri(origin).Host == "localhost" || 
                    origin.Contains("vercel.app") ||
                    origin.Contains("railway.app")
                  )
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials(); 
        });
});

var jwtKey = builder.Configuration["Jwt:Key"] ?? "GMP_WHO_Default_Secret_Key_Minimum_32_Characters_Long_123456789";
var key = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false; 
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});


// Extra policy removed to avoid confusion; "AllowVercelAndLocal" handles everything.


var app = builder.Build();

// Simple Health Check
app.MapGet("/health", () => "OK");

// ============================================================
// 6. DB INITIALIZATION (Cleanup: Data is now in SQL Scripts)
// ============================================================
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var db = services.GetRequiredService<GmpContext>();

    // 6.1. Connection Retry Logic
    int maxConnectRetries = 15;
    for (int i = 1; i <= maxConnectRetries; i++)
    {
        try {
            Console.WriteLine($"[BACKEND] Connection attempt {i}/{maxConnectRetries}...");
            
            // Check if we can even ping the DB
            if (!db.Database.CanConnect())
            {
                Console.WriteLine("[BACKEND] Database.CanConnect() returned FALSE. Host might be unreachable or DB doesn't exist yet.");
            }
            
            Console.WriteLine("[BACKEND] Running EnsureCreated...");
            bool isNewlyCreated = db.Database.EnsureCreated();
            
            // Check if AppUsers table is empty to determine if we need to seed
            bool needsSeeding = isNewlyCreated || !db.AppUsers.Any();
            
            if (needsSeeding)
            {
                Console.WriteLine("[BACKEND] Database is new or empty. Seeding data via EF Core...");
                try 
                {
                    string[] possiblePaths = {
                        "/app/DATABASE",
                        Path.Combine(Directory.GetCurrentDirectory(), "DATABASE"),
                        Path.Combine(Directory.GetParent(Directory.GetCurrentDirectory())?.FullName ?? "", "DATABASE")
                    };
                    
                    string baseDir = possiblePaths.FirstOrDefault(Directory.Exists) ?? "";

                    var scripts = new[] { "Schema.sql", "SystemAudit.sql", "full_seed.sql", "hotfix.sql" };
                    foreach (var script in scripts)
                    {
                        var path = Path.Combine(baseDir, script);
                        if (System.IO.File.Exists(path))
                        {
                            Console.WriteLine($"[BACKEND] Running script: {script}");
                            var sql = System.IO.File.ReadAllText(path, System.Text.Encoding.UTF8);
                            // Split by GO batch separator
                            var batches = System.Text.RegularExpressions.Regex.Split(
                                sql, 
                                @"^\s*GO\s*$", 
                                System.Text.RegularExpressions.RegexOptions.Multiline | System.Text.RegularExpressions.RegexOptions.IgnoreCase
                            );
                            
                            foreach (var batch in batches)
                            {
                                var trimmedBatch = batch.Trim();
                                if (!string.IsNullOrWhiteSpace(trimmedBatch))
                                {
                                    // Remove USE statements as they are not needed/supported in this context
                                    if (trimmedBatch.StartsWith("USE [", StringComparison.OrdinalIgnoreCase) || 
                                        trimmedBatch.StartsWith("USE master", StringComparison.OrdinalIgnoreCase))
                                    {
                                        continue;
                                    }
                                    
                                    using (var command = db.Database.GetDbConnection().CreateCommand())
                                    {
                                        command.CommandText = trimmedBatch;
                                        command.CommandType = System.Data.CommandType.Text;
                                        if (command.Connection.State != System.Data.ConnectionState.Open)
                                        {
                                            command.Connection.Open();
                                        }
                                        command.ExecuteNonQuery();
                                    }
                                }
                            }
                        }
                        else
                        {
                            Console.WriteLine($"[BACKEND] WARNING: Script {script} not found at {path}");
                        }
                    }
                    Console.WriteLine("[BACKEND] Database Seeding Completed Successfully.");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[BACKEND] Seeding failed: {ex.Message}");
                }
            }
            
            Console.WriteLine("[BACKEND] Database is ONLINE and Initialized.");
            break;
        } catch (Exception ex) {
            Console.WriteLine($"[BACKEND] Connection failed with exception: {ex.GetType().Name} - {ex.Message}");
            if (ex.InnerException != null) 
                Console.WriteLine($"[BACKEND] Inner Exception: {ex.InnerException.Message}");
            
            if (i == maxConnectRetries) throw;
            Console.WriteLine("[BACKEND] Retrying in 5 seconds...");
            Thread.Sleep(5000);
        }
    }
}

// ============================================================
// 7. PIPELINE
// ============================================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection(); // Disable redirection behind reverse proxies (Railway/Vercel) to prevent infinite loops or mixed content errors.

app.UseCors("AllowVercelAndLocal");

app.UseAuthentication();   
app.UseAuthorization();
app.MapControllers();

// ------------------------------------------------------------
// 8. METRICS & EXTENDED HEALTH
// ------------------------------------------------------------
app.UseHttpMetrics(); // Prometheus HTTP metrics middleware
app.MapMetrics(); // Expose /metrics endpoint

// Enhanced health check with DB connectivity
app.MapGet("/healthcheck", async (GmpContext db) =>
{
    var canConnect = await db.Database.CanConnectAsync();
    return Results.Json(new { status = canConnect ? "healthy" : "unhealthy", time = DateTime.UtcNow });
}).AllowAnonymous();

app.Run();


