
using GMP_System.Entities;
using GMP_System.Interfaces;
using GMP_System.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Text.Json.Serialization;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Ngăn chặn lỗi vòng lặp (Recipe -> BOM -> Recipe...)
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
    });
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();


// 1. Đăng ký Database Context
// --- Tìm đoạn này ---
builder.Services.AddDbContext<GmpContext>((sp, options) =>
{
    // Lấy chuỗi kết nối
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

    // --- THÊM DÒNG NÀY ĐỂ GẮN INTERCEPTOR ---
    options.AddInterceptors(new GMP_System.Interceptors.AuditLogInterceptor());
    // ----------------------------------------

    options.UseSqlServer(connectionString);
});

// 2. Đăng ký UnitOfWork (Scoped: Mỗi request HTTP tạo 1 instance mới)
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
