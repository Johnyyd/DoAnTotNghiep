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
// 6. DB INITIALIZATION & ROBUST SEEDING (10 Diverse Scenarios)
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

    // 6.2. Seed logic using EF Core (Enhanced Scenarios)
    if (!db.Materials.Any())
    {
        Console.WriteLine("[BACKEND] Starting Enhanced Data Seeding (10 Scenarios)...");
        
        // --- 1. USERS ---
        var admin = new AppUser { Username = "admin", FullName = "Admin System", Role = "Admin", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"), IsActive = true };
        var qc01 = new AppUser { Username = "qc01", FullName = "Trần Kiểm Tra", Role = "QA_QC", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Qc@123456"), IsActive = true };
        var op01 = new AppUser { Username = "op01", FullName = "Nguyễn Công Nhân", Role = "Operator", PasswordHash = BCrypt.Net.BCrypt.HashPassword("Op@123456"), IsActive = true };
        db.AppUsers.AddRange(admin, qc01, op01);
        db.SaveChanges();

        // --- 2. UNITS ---
        var uomKg = new UnitOfMeasure { UomName = "kg", Description = "Kilogram" };
        var uomCap = new UnitOfMeasure { UomName = "Tablets", Description = "Viên" };
        var uomBox = new UnitOfMeasure { UomName = "Box", Description = "Hộp" };
        db.UnitOfMeasures.AddRange(uomKg, uomCap, uomBox);
        db.SaveChanges();

        // --- 3. EQUIPMENTS ---
        var eqpScales = new Equipment { EquipmentCode = "EQP-WGH-01", EquipmentName = "Cân điện tử", Status = "Ready" };
        var eqpDry = new Equipment { EquipmentCode = "EQP-DRY-01", EquipmentName = "Máy sấy tầng sôi", Status = "Ready" };
        var eqpMix = new Equipment { EquipmentCode = "EQP-MIX-01", EquipmentName = "Máy trộn lập phương", Status = "Ready" };
        db.Equipments.AddRange(eqpScales, eqpDry, eqpMix);
        db.SaveChanges();

        // --- 4. MATERIALS & RECIPE 1: NLC 3 Capsule ---
        var matNlc = new Material { MaterialCode = "MAT-NLC3", MaterialName = "Hoạt chất NLC 3", Type = "RawMaterial", BaseUomId = uomKg.UomId };
        var matFgNlc = new Material { MaterialCode = "FG-NLC3", MaterialName = "Viên nang NLC 3", Type = "FinishedGood", BaseUomId = uomBox.UomId };
        db.Materials.AddRange(matNlc, matFgNlc);
        db.SaveChanges();

        var recipeNlc = new Recipe { MaterialId = matFgNlc.MaterialId, VersionNumber = 1, BatchSize = 100000, Status = "Approved", ApprovedBy = admin.UserId, ApprovedDate = DateTime.Now };
        db.Recipes.Add(recipeNlc);
        db.SaveChanges();

        var routingsNlc = new List<RecipeRouting> {
            new RecipeRouting { RecipeId = recipeNlc.RecipeId, StepNumber = 1, StepName = "Cân Nguyên Liệu", DefaultEquipmentId = eqpScales.EquipmentId },
            new RecipeRouting { RecipeId = recipeNlc.RecipeId, StepNumber = 2, StepName = "Sấy Nguyên Liệu", DefaultEquipmentId = eqpDry.EquipmentId },
            new RecipeRouting { RecipeId = recipeNlc.RecipeId, StepNumber = 3, StepName = "Trộn Khô", DefaultEquipmentId = eqpMix.EquipmentId }
        };
        db.RecipeRoutings.AddRange(routingsNlc);
        db.SaveChanges();

        // --- 5. MATERIALS & RECIPE 2: Paracetamol ---
        var matPara = new Material { MaterialCode = "MAT-PARA", MaterialName = "Bột Paracetamol", Type = "RawMaterial", BaseUomId = uomKg.UomId };
        var matFgPara = new Material { MaterialCode = "FG-PARA", MaterialName = "Viên nén Paracetamol", Type = "FinishedGood", BaseUomId = uomBox.UomId };
        db.Materials.AddRange(matPara, matFgPara);
        db.SaveChanges();

        var recipePara = new Recipe { MaterialId = matFgPara.MaterialId, VersionNumber = 1, BatchSize = 500000, Status = "Approved", ApprovedBy = admin.UserId, ApprovedDate = DateTime.Now };
        db.Recipes.Add(recipePara);
        db.SaveChanges();

        var routingsPara = new List<RecipeRouting> {
            new RecipeRouting { RecipeId = recipePara.RecipeId, StepNumber = 1, StepName = "Cân Bột", DefaultEquipmentId = eqpScales.EquipmentId },
            new RecipeRouting { RecipeId = recipePara.RecipeId, StepNumber = 2, StepName = "Dập Viên", DefaultEquipmentId = eqpMix.EquipmentId }
        };
        db.RecipeRoutings.AddRange(routingsPara);
        db.SaveChanges();

        // --- 6. PRODUCTION ORDERS & BATCHES ---
        var now = DateTime.Now;

        // SCENARIO 1: PO-001 - Hoàn thành 100%
        var po1 = new ProductionOrder { OrderCode = "PO-001", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 100000, ActualQuantity = 100050, Status = "Completed", CreatedBy = admin.UserId, StartDate = now.AddDays(-2), EndDate = now.AddDays(-1) };
        db.ProductionOrders.Add(po1);
        db.SaveChanges();
        var b1 = new ProductionBatch { OrderId = po1.OrderId, BatchNumber = "B26001", Status = "Completed", ManufactureDate = po1.StartDate, EndTime = po1.EndDate, CurrentStep = 3 };
        db.ProductionBatches.Add(b1);
        db.SaveChanges();
        // Logs for B1
        db.BatchProcessLogs.AddRange(
            new BatchProcessLog { BatchId = b1.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddDays(-2), EndTime = now.AddDays(-1.9), ResultStatus = "Passed", ParametersData = "{\"weight\": 100.05, \"unit\": \"kg\"}" },
            new BatchProcessLog { BatchId = b1.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddDays(-1.8), EndTime = now.AddDays(-1.5), ResultStatus = "Passed", ParametersData = "{\"temp\": 60.5, \"humidity\": 3.2}" },
            new BatchProcessLog { BatchId = b1.BatchId, RoutingId = routingsNlc[2].RoutingId, EquipmentId = eqpMix.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddDays(-1.4), EndTime = now.AddDays(-1.1), ResultStatus = "Passed", ParametersData = "{\"speed\": 30, \"time\": 45}" }
        );

        // SCENARIO 2: PO-002 - Đang chạy (Đồng bộ: In-Process)
        var po2 = new ProductionOrder { OrderCode = "PO-002", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 300000, Status = "In-Process", CreatedBy = admin.UserId, StartDate = now };
        db.ProductionOrders.Add(po2);
        db.SaveChanges();
        // 3 Batches: 2 Completed, 1 InProcess
        var b2_1 = new ProductionBatch { OrderId = po2.OrderId, BatchNumber = "B26002-A", Status = "Completed", ManufactureDate = now.AddHours(-12), EndTime = now.AddHours(-10), CurrentStep = 3 };
        var b2_2 = new ProductionBatch { OrderId = po2.OrderId, BatchNumber = "B26002-B", Status = "Completed", ManufactureDate = now.AddHours(-8), EndTime = now.AddHours(-6), CurrentStep = 3 };
        var b2_3 = new ProductionBatch { OrderId = po2.OrderId, BatchNumber = "B26002-C", Status = "InProcess", ManufactureDate = now, CurrentStep = 2 };
        db.ProductionBatches.AddRange(b2_1, b2_2, b2_3);
        db.SaveChanges();
        // Sequential logs for PO-002
        db.BatchProcessLogs.AddRange(
            // B26002-A Completed
            new BatchProcessLog { BatchId = b2_1.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-12), EndTime = now.AddHours(-11.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b2_1.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-11.4), EndTime = now.AddHours(-10.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b2_1.BatchId, RoutingId = routingsNlc[2].RoutingId, EquipmentId = eqpMix.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-10.4), EndTime = now.AddHours(-10), ResultStatus = "Passed" },
            // B26002-B Completed
            new BatchProcessLog { BatchId = b2_2.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-8), EndTime = now.AddHours(-7.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b2_2.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-7.4), EndTime = now.AddHours(-6.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b2_2.BatchId, RoutingId = routingsNlc[2].RoutingId, EquipmentId = eqpMix.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-6.4), EndTime = now.AddHours(-6), ResultStatus = "Passed" },
            // B26002-C InProcess (Step 1 Passed, Step 2 Running)
            new BatchProcessLog { BatchId = b2_3.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-1), EndTime = now.AddHours(-0.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b2_3.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-0.4), ResultStatus = "Running" }
        );

        // SCENARIO 3: PO-003 - Tạm dừng (Thử nghiệm: Hold)
        var po3 = new ProductionOrder { OrderCode = "PO-003", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 150000, Status = "Hold", CreatedBy = admin.UserId, StartDate = now };
        db.ProductionOrders.Add(po3);
        db.SaveChanges();
        var b3 = new ProductionBatch { OrderId = po3.OrderId, BatchNumber = "B26003", Status = "OnHold", ManufactureDate = now, CurrentStep = 2 };
        db.ProductionBatches.Add(b3);
        db.SaveChanges();
        // Step 1 Passed, Step 2 Hold
        db.BatchProcessLogs.AddRange(
            new BatchProcessLog { BatchId = b3.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-2), EndTime = now.AddHours(-1.5), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b3.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-1.4), ResultStatus = "OnHold" }
        );

        // SCENARIO 4: PO-004 - Đang chạy khác (Lỗi logic fix)
        var po4 = new ProductionOrder { OrderCode = "PO-004", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 200000, Status = "In-Process", CreatedBy = admin.UserId, StartDate = now };
        db.ProductionOrders.Add(po4);
        db.SaveChanges();
        var b4_fail = new ProductionBatch { OrderId = po4.OrderId, BatchNumber = "B26004-X", Status = "InProcess", ManufactureDate = now, CurrentStep = 2 };
        db.ProductionBatches.Add(b4_fail);
        db.SaveChanges();
        // Sequential logs: Step 1 Passed, Step 2 Failed
        db.BatchProcessLogs.AddRange(
            new BatchProcessLog { BatchId = b4_fail.BatchId, RoutingId = routingsNlc[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-3), EndTime = now.AddHours(-2), ResultStatus = "Passed" },
            new BatchProcessLog { BatchId = b4_fail.BatchId, RoutingId = routingsNlc[1].RoutingId, EquipmentId = eqpDry.EquipmentId, OperatorId = op01.UserId, StartTime = now.AddHours(-1.9), ResultStatus = "Failed" }
        );

        // SCENARIO 5: PO-005 - Kế hoạch tương lai (Approved)
        db.ProductionOrders.Add(new ProductionOrder { OrderCode = "PO-005", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 500000, Status = "Approved", CreatedBy = admin.UserId, StartDate = now.AddDays(7) });

        // SCENARIO 6: PO-006 - Sản phẩm Paracetamol (In-Process)
        var po6 = new ProductionOrder { OrderCode = "PO-006", RecipeId = recipePara.RecipeId, PlannedQuantity = 500000, Status = "In-Process", CreatedBy = admin.UserId, StartDate = now };
        db.ProductionOrders.Add(po6);
        db.SaveChanges();
        var bPara = new ProductionBatch { OrderId = po6.OrderId, BatchNumber = "BPARA-01", Status = "InProcess", ManufactureDate = now, CurrentStep = 1 };
        db.ProductionBatches.Add(bPara);
        db.SaveChanges();
        // Just Step 1 Running
        db.BatchProcessLogs.Add(new BatchProcessLog { BatchId = bPara.BatchId, RoutingId = routingsPara[0].RoutingId, EquipmentId = eqpScales.EquipmentId, OperatorId = op01.UserId, StartTime = now, ResultStatus = "Running" });

        // SCENARIO 7: PO-007 - Số lượng cực lớn
        db.ProductionOrders.Add(new ProductionOrder { OrderCode = "PO-007", RecipeId = recipePara.RecipeId, PlannedQuantity = 1000000, Status = "Approved", CreatedBy = admin.UserId, StartDate = now.AddDays(30) });

        // SCENARIO 8: PO-008 - Ghi chú đặc biệt (Draft: Nhãn Cam)
        db.ProductionOrders.Add(new ProductionOrder { OrderCode = "PO-008", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 100000, Status = "Draft", CreatedBy = admin.UserId });

        // OTHER Scenarios
        db.ProductionOrders.Add(new ProductionOrder { OrderCode = "PO-009", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 100000, Status = "Cancelled" });
        db.ProductionOrders.Add(new ProductionOrder { OrderCode = "PO-010", RecipeId = recipeNlc.RecipeId, PlannedQuantity = 100000, Status = "Draft" });

        db.SaveChanges();
        Console.WriteLine("[BACKEND] 10 Scenarios seeded successfully with logical sequences.");
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
