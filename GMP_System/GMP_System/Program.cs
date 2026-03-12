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

    // Seed data if empty
    if (!db.Materials.Any())
    {
        var unit1 = new UnitOfMeasure { Code = "KG", Name = "Kilogram", Description = "Kilogram" };
        var unit2 = new UnitOfMeasure { Code = "G", Name = "Gram", Description = "Gram" };
        var unit3 = new UnitOfMeasure { Code = "TAB", Name = "Tablet", Description = "Tablet" };
        db.UnitOfMeasures.AddRange(unit1, unit2, unit3);
        db.SaveChanges();

        var material1 = new Material
        {
            MaterialCode = "MAT-001",
            MaterialName = "Paracetamol 500mg",
            Type = "RawMaterial",
            BaseUomId = unit3.UnitId,
            IsActive = true,
            Description = "Active ingredient for pain relief",
            CreatedAt = DateTime.Now
        };
        var material2 = new Material
        {
            MaterialCode = "MAT-002",
            MaterialName = "Microcrystalline Cellulose",
            Type = "RawMaterial",
            BaseUomId = unit1.UnitId,
            IsActive = true,
            Description = "Excipient binder",
            CreatedAt = DateTime.Now
        };
        var material3 = new Material
        {
            MaterialCode = "MAT-003",
            MaterialName = "Para Film",
            Type = "Packaging",
            BaseUomId = unit2.UnitId,
            IsActive = true,
            Description = "Packaging film for blisters",
            CreatedAt = DateTime.Now
        };
        db.Materials.AddRange(material1, material2, material3);

        var recipe1 = new Recipe
        {
            MaterialId = material1.MaterialId,
            BatchSize = 1000,
            Status = "Draft",
            VersionNumber = 1,
            CreatedAt = DateTime.Now,
            EffectiveDate = DateTime.Now.AddDays(1),
            Note = "Initial draft"
        };
        db.Recipes.Add(recipe1);
        db.SaveChanges();

        // Add recipe BOM
        if (recipe1.RecipeId > 0)
        {
            db.RecipeBoms.Add(new RecipeBom
            {
                RecipeId = recipe1.RecipeId,
                MaterialId = material2.MaterialId,
                Quantity = 0.5m,
                UomId = unit1.UnitId
            });
        }

        db.SaveChanges();
    }
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
