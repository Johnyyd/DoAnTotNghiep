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
using System.Text.RegularExpressions;
using System.IO;
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
// 6. DB INITIALIZATION & ROBUST SEEDING
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

    // 6.2. Seed logic using EF Core (Full Scenario Set)
    if (!db.Materials.Any())
    {
        Console.WriteLine("[BACKEND] Starting Full Data Seeding (EF Core)...");
        
        // 1. Users
        var admin = new AppUser { Username = "admin", FullName = "Admin System", Role = "Admin", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"), IsActive = true };
        var qc01 = new AppUser { Username = "qc01", FullName = "Trần Kiểm Tra", Role = "QA_QC", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Qc@123456"), IsActive = true };
        var op01 = new AppUser { Username = "op01", FullName = "Nguyễn Công Nhân", Role = "Operator", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Op@123456"), IsActive = true };
        db.AppUsers.AddRange(admin, qc01, op01);
        db.SaveChanges();
        Console.WriteLine("[BACKEND] Users seeded.");

        // 2. Units
        var uomKg = new UnitOfMeasure { UomName = "kg", Description = "Kilogram" };
        var uomCap = new UnitOfMeasure { UomName = "Tablet/Capsule", Description = "Viên" };
        var uomBox = new UnitOfMeasure { UomName = "Box", Description = "Hộp" };
        db.UnitOfMeasures.AddRange(uomKg, uomCap, uomBox);
        db.SaveChanges();

        // 3. Equipments
        var eqpDry = new Equipment { EquipmentCode = "EQP-DRY-01", EquipmentName = "Máy sấy tầng sôi", Status = "Ready" };
        var eqpMix = new Equipment { EquipmentCode = "EQP-MIX-01", EquipmentName = "Máy trộn lập phương", Status = "Ready" };
        db.Equipments.AddRange(eqpDry, eqpMix);
        db.SaveChanges();

        // 4. Materials
        var matNlc = new Material { MaterialCode = "MAT-NLC3", MaterialName = "Hoạt chất NLC 3", Type = "RawMaterial", BaseUomId = uomKg.UomId };
        var matFg = new Material { MaterialCode = "FG-NLC3-CAP", MaterialName = "Viên nang NLC 3", Type = "FinishedGood", BaseUomId = uomBox.UomId };
        db.Materials.AddRange(matNlc, matFg);
        db.SaveChanges();

        // 5. Recipe
        var recipe = new Recipe { MaterialId = matFg.MaterialId, VersionNumber = 1, BatchSize = 100000, Status = "Approved", ApprovedBy = admin.UserId, ApprovedDate = DateTime.Now };
        db.Recipes.Add(recipe);
        db.SaveChanges();

        // 6. Routing
        var step1 = new RecipeRouting { RecipeId = recipe.RecipeId, StepNumber = 1, StepName = "Cân Nguyên Liệu" };
        var step2 = new RecipeRouting { RecipeId = recipe.RecipeId, StepNumber = 2, StepName = "Sấy Nguyên Liệu", DefaultEquipmentId = eqpDry.EquipmentId };
        var step3 = new RecipeRouting { RecipeId = recipe.RecipeId, StepNumber = 3, StepName = "Trộn Khô", DefaultEquipmentId = eqpMix.EquipmentId };
        db.RecipeRoutings.AddRange(step1, step2, step3);
        db.SaveChanges();

        // 7. Production Orders (5 Scenarios)
        var orders = new List<ProductionOrder> {
            new ProductionOrder { OrderCode = "PO-2026-NLC-001", RecipeId = recipe.RecipeId, PlannedQuantity = 100000, Status = "Completed", CreatedBy = admin.UserId, StartDate = DateTime.Now.AddDays(-5), EndDate = DateTime.Now.AddDays(-4) },
            new ProductionOrder { OrderCode = "PO-2026-NLC-002", RecipeId = recipe.RecipeId, PlannedQuantity = 200000, Status = "InProcess", CreatedBy = admin.UserId, StartDate = DateTime.Now },
            new ProductionOrder { OrderCode = "PO-2026-NLC-003", RecipeId = recipe.RecipeId, PlannedQuantity = 150000, Status = "Hold", CreatedBy = admin.UserId, StartDate = DateTime.Now.AddDays(-2) },
            new ProductionOrder { OrderCode = "PO-2026-NLC-004", RecipeId = recipe.RecipeId, PlannedQuantity = 300000, Status = "Approved", CreatedBy = admin.UserId, StartDate = DateTime.Now.AddDays(2) },
            new ProductionOrder { OrderCode = "PO-2026-NLC-005", RecipeId = recipe.RecipeId, PlannedQuantity = 50000, Status = "Draft", CreatedBy = admin.UserId, StartDate = DateTime.Now.AddDays(10) }
        };
        db.ProductionOrders.AddRange(orders);
        db.SaveChanges();

        // 8. Batches for InProcess Order
        var batchRunning = new ProductionBatch { OrderId = orders[1].OrderId, BatchNumber = "B260302", Status = "InProcess", ManufactureDate = DateTime.Now, CurrentStep = 2 };
        db.ProductionBatches.Add(batchRunning);
        db.SaveChanges();

        Console.WriteLine("[BACKEND] All data seeded successfully (5 PO Scenarios).");
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

app.MapGet("/health", () => Results.Json(new { status = "healthy", time = DateTime.UtcNow }))
   .AllowAnonymous();

app.UseCors("AllowFrontend");
app.UseHttpsRedirection();
app.UseAuthentication();   
app.UseAuthorization();
app.MapControllers();

app.Run();
