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
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
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
            policy.WithOrigins(
                    "https://do-an-tot-nghiep-mz49c8gbc-johnyyds-projects.vercel.app", // Link Vercel
                    "http://localhost:8080", // Frontend Local
                    "http://localhost:8081"  // Mobile Local
                  )
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials(); // Bắt buộc phải có để gửi token/cookie
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


builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowVercel",
        policy =>
        {
            policy.WithOrigins("https://do-an-tot-nghiep-mz49c8gbc-johnyyds-projects.vercel.app") // Thay bằng đúng link Vercel ở ảnh của bạn
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials(); 
        });
});


var app = builder.Build();

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
            if (!db.Database.CanConnect())
            {
                Console.WriteLine("[BACKEND] Database.CanConnect() returned FALSE. SQL Server might not be ready for this DB yet.");
            }
            
            Console.WriteLine("[BACKEND] Running EnsureCreated...");
            db.Database.EnsureCreated();
            
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

app.UseHttpsRedirection();

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


