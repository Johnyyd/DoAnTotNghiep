using GMP_System.Entities;
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
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:8080", "http://localhost:8081", "http://localhost")
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
            db.Database.CanConnect();
            db.Database.EnsureCreated();
            Console.WriteLine("[BACKEND] Database is ONLINE.");
            break;
        } catch (Exception ex) {
            Console.WriteLine($"[BACKEND] Connection failed: {ex.Message}");
            if (i == maxConnectRetries) throw;
            Thread.Sleep(5000);
        }
    }
    
    // NOTE: Seeding logic has been moved to DATABASE/full_seed.sql
    // Please execute the SQL script manually or via Docker entrypoint.
}

// ============================================================
// 7. PIPELINE
// ============================================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/health", () => Results.Json(new { status = "healthy", time = DateTime.UtcNow }))
   .AllowAnonymous();

app.UseCors("AllowFrontend");
app.UseHttpsRedirection();
app.UseAuthentication();   
app.UseAuthorization();
app.MapControllers();

app.Run();
