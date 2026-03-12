using GMP_System.Entities;
using GMP_System.Interfaces;
using GMP_System.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Ngăn chặn lỗi vòng lặp (Recipe -> BOM -> Recipe...)
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
    });

// CORS policy - allow frontend to access API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy.WithOrigins(
                    "http://localhost:8080",
                    "http://100.89.137.3:8080"
                )
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});

// 1. Đăng ký Database Context
builder.Services.AddDbContext<GmpContext>((sp, options) =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    options.AddInterceptors(new GMP_System.Interceptors.AuditLogInterceptor());
    options.UseSqlServer(connectionString);
});

// 2. Đăng ký UnitOfWork
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

var app = builder.Build();

// Initialize database (Code First)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<GmpContext>();
    db.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // Simple health check endpoint
    app.MapGet("/health", () => Results.Json(new { status = "healthy", timestamp = DateTime.UtcNow }));
}

app.UseCors("AllowFrontend");
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
