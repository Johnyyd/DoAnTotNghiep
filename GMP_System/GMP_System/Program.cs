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
        var unit1 = new UnitOfMeasure { UomName = "Kilogram", Description = "Kilogram" };
        var unit2 = new UnitOfMeasure { UomName = "Gram", Description = "Gram" };
        var unit3 = new UnitOfMeasure { UomName = "Tablet", Description = "Tablet" };
        db.UnitOfMeasures.AddRange(unit1, unit2, unit3);
        db.SaveChanges();

        var material1 = new Material
        {
            MaterialCode = "MAT-001",
            MaterialName = "Paracetamol 500mg",
            Type = "RawMaterial",
            BaseUomId = unit3.UomId,
            IsActive = true,
            Description = "Active ingredient for pain relief",
            CreatedAt = DateTime.Now
        };
        var material2 = new Material
        {
            MaterialCode = "MAT-002",
            MaterialName = "Microcrystalline Cellulose",
            Type = "RawMaterial",
            BaseUomId = unit1.UomId,
            IsActive = true,
            Description = "Excipient binder",
            CreatedAt = DateTime.Now
        };
        var material3 = new Material
        {
            MaterialCode = "MAT-003",
            MaterialName = "Para Film",
            Type = "Packaging",
            BaseUomId = unit2.UomId,
            IsActive = true,
            Description = "Packaging film for blister packs",
            CreatedAt = DateTime.Now
        };
        db.Materials.AddRange(material1, material2, material3);
        db.SaveChanges();

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
        db.RecipeBoms.Add(new RecipeBom
        {
            RecipeId = recipe1.RecipeId,
            MaterialId = material2.MaterialId,
            Quantity = 0.5m,
            UomId = unit1.UomId
        });
        db.RecipeBoms.Add(new RecipeBom
        {
            RecipeId = recipe1.RecipeId,
            MaterialId = material3.MaterialId,
            Quantity = 0.1m,
            UomId = unit2.UomId
        });

        // Seed Inventory Lots (for materials 2 and 3)
        var lot1 = new InventoryLot
        {
            MaterialId = material2.MaterialId,
            LotNumber = "LOT-MCC-001",
            QuantityCurrent = 100,
            ManufactureDate = DateTime.Now.AddMonths(-1),
            ExpiryDate = DateTime.Now.AddMonths(11),
            Qcstatus = "Released"
        };
        var lot2 = new InventoryLot
        {
            MaterialId = material3.MaterialId,
            LotNumber = "LOT-FILM-001",
            QuantityCurrent = 500,
            ManufactureDate = DateTime.Now.AddMonths(-2),
            ExpiryDate = DateTime.Now.AddMonths(10),
            Qcstatus = "Released"
        };
        db.InventoryLots.AddRange(lot1, lot2);
        db.SaveChanges();

        // Seed Production Order
        var order1 = new ProductionOrder
        {
            OrderCode = "PO-001",
            RecipeId = recipe1.RecipeId,
            PlannedQuantity = 1000,
            ActualQuantity = 980,
            Status = "Completed",
            CreatedAt = DateTime.Now,
            StartDate = DateTime.Now.AddDays(-7),
            EndDate = DateTime.Now.AddDays(-6)
        };
        db.ProductionOrders.Add(order1);
        db.SaveChanges();

        // Seed Production Batch
        var batch1 = new ProductionBatch
        {
            OrderId = order1.OrderId,
            BatchNumber = "BATCH-PCM-001",
            ManufactureDate = DateTime.Now.AddDays(-7),
            EndTime = DateTime.Now.AddDays(-6),
            Status = "Completed"
        };
        db.ProductionBatches.Add(batch1);
        db.SaveChanges();

        // Seed Material Usages linking batch and lots
        db.MaterialUsages.Add(new MaterialUsage
        {
            BatchId = batch1.BatchId,
            InventoryLotId = lot1.LotId,
            ActualAmount = 50,
            Timestamp = DateTime.Now.AddDays(-7),
            Note = "Used in batch BATCH-PCM-001"
        });
        db.MaterialUsages.Add(new MaterialUsage
        {
            BatchId = batch1.BatchId,
            InventoryLotId = lot2.LotId,
            ActualAmount = 100,
            Timestamp = DateTime.Now.AddDays(-7),
            Note = "Used in batch BATCH-PCM-001"
        });

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
