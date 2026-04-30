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
            
            // 1. Update columns
            Console.WriteLine("[BACKEND] Running EnsureColumnsAsync...");
            await EnsureColumnsAsync(db);
            
            // 2. Seed Data
            Console.WriteLine("[BACKEND] Running EnsureUserSeedAsync...");
            await EnsureUserSeedAsync(db);
            
            Console.WriteLine("[BACKEND] Running EnsureDefaultInventorySeedAsync...");
            await EnsureDefaultInventorySeedAsync(db);
            
            // 3. Add triggers
            Console.WriteLine("[BACKEND] Running EnsureTriggersAsync...");
            await EnsureTriggersAsync(db);

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

static async Task EnsureDefaultInventorySeedAsync(GmpContext db)
{
    var today = DateTime.Today;
    await EnsureAreaSeedAsync(db);

    var materials = await db.Materials.ToListAsync();

    foreach (var material in materials.Where(m => !string.Equals(m.Type, "FinishedGood", StringComparison.OrdinalIgnoreCase)))
    {
        var lots = await db.InventoryLots.Where(l => l.MaterialId == material.MaterialId).ToListAsync();
        if (!lots.Any())
        {
            db.InventoryLots.Add(new InventoryLot
            {
                MaterialId = material.MaterialId,
                LotNumber = $"INIT-{material.MaterialCode}-{today:yyMMdd}",
                QuantityCurrent = 100m,
                ManufactureDate = today,
                ExpiryDate = today.AddYears(2),
                QCStatus = "Approved"
            });
            continue;
        }

        var total = lots.Sum(x => x.QuantityCurrent);
        if (total <= 0)
        {
            db.InventoryLots.Add(new InventoryLot
            {
                MaterialId = material.MaterialId,
                LotNumber = $"TOPUP-{material.MaterialCode}-{today:yyMMdd}",
                QuantityCurrent = 100m,
                ManufactureDate = today,
                ExpiryDate = today.AddYears(2),
                QCStatus = "Approved"
            });
        }
    }

    // Add demo finished-good lots for traceability screen when absent.
    var finishedGoods = materials
        .Where(m => string.Equals(m.Type, "FinishedGood", StringComparison.OrdinalIgnoreCase))
        .OrderBy(m => m.MaterialId)
        .Take(2)
        .ToList();

    var demoLotCodes = new[] { "B26-007-01", "B26-007-02" };
    for (var i = 0; i < finishedGoods.Count && i < demoLotCodes.Length; i++)
    {
        var code = demoLotCodes[i];
        var exists = await db.InventoryLots.AnyAsync(l => l.LotNumber == code);
        if (exists)
        {
            continue;
        }

        db.InventoryLots.Add(new InventoryLot
        {
            MaterialId = finishedGoods[i].MaterialId,
            LotNumber = code,
            QuantityCurrent = 2m,
            ManufactureDate = today,
            ExpiryDate = today.AddYears(2),
            QCStatus = "Completed"
        });
    }

    await db.SaveChangesAsync();
}

static async Task EnsureColumnsAsync(GmpContext db)
{
    const string sql = @"
IF OBJECT_ID('dbo.ProductionAreas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductionAreas (
        AreaId INT IDENTITY(1,1) PRIMARY KEY,
        AreaCode VARCHAR(50) NOT NULL UNIQUE,
        AreaName NVARCHAR(200) NOT NULL,
        Description NVARCHAR(500) NULL
    );
END;

IF COL_LENGTH('dbo.Equipments','TechnicalSpecification') IS NULL
    ALTER TABLE dbo.Equipments ADD TechnicalSpecification NVARCHAR(300) NULL;
IF COL_LENGTH('dbo.Equipments','UsagePurpose') IS NULL
    ALTER TABLE dbo.Equipments ADD UsagePurpose NVARCHAR(300) NULL;
IF COL_LENGTH('dbo.Equipments','AreaId') IS NULL
    ALTER TABLE dbo.Equipments ADD AreaId INT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Equipments_ProductionAreas')
    ALTER TABLE dbo.Equipments ADD CONSTRAINT FK_Equipments_ProductionAreas FOREIGN KEY (AreaId) REFERENCES dbo.ProductionAreas(AreaId);

IF COL_LENGTH('dbo.RecipeBom','TechnicalStandard') IS NULL
    ALTER TABLE dbo.RecipeBom ADD TechnicalStandard NVARCHAR(100) NULL;

IF COL_LENGTH('dbo.RecipeRouting','MaterialId') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD MaterialId INT NULL;
IF COL_LENGTH('dbo.RecipeRouting','AreaId') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD AreaId INT NULL;
IF COL_LENGTH('dbo.RecipeRouting','CleanlinessStatus') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD CleanlinessStatus NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.RecipeRouting','StandardTemperature') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD StandardTemperature NVARCHAR(50) NULL;
ELSE
    ALTER TABLE dbo.RecipeRouting ALTER COLUMN StandardTemperature NVARCHAR(50) NULL;

IF COL_LENGTH('dbo.RecipeRouting','StandardHumidity') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD StandardHumidity NVARCHAR(50) NULL;
ELSE
    ALTER TABLE dbo.RecipeRouting ALTER COLUMN StandardHumidity NVARCHAR(50) NULL;

IF COL_LENGTH('dbo.RecipeRouting','StandardPressure') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD StandardPressure NVARCHAR(50) NULL;
ELSE
    ALTER TABLE dbo.RecipeRouting ALTER COLUMN StandardPressure NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.RecipeRouting','StabilityStatus') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD StabilityStatus NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.RecipeRouting','SetTemperature') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD SetTemperature DECIMAL(10,2) NULL;
IF COL_LENGTH('dbo.RecipeRouting','SetTimeMinutes') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD SetTimeMinutes INT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RecipeRouting_Materials')
    ALTER TABLE dbo.RecipeRouting ADD CONSTRAINT FK_RecipeRouting_Materials FOREIGN KEY (MaterialId) REFERENCES dbo.Materials(MaterialId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RecipeRouting_ProductionAreas')
    ALTER TABLE dbo.RecipeRouting ADD CONSTRAINT FK_RecipeRouting_ProductionAreas FOREIGN KEY (AreaId) REFERENCES dbo.ProductionAreas(AreaId);

-- Missing column for RecipeRouting
IF COL_LENGTH('dbo.RecipeRouting','NumberOfRouting') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD NumberOfRouting INT NULL DEFAULT 1;

IF COL_LENGTH('dbo.RecipeRouting','OrderId') IS NULL
    ALTER TABLE dbo.RecipeRouting ADD OrderId INT NULL;

-- Missing column for Materials
IF COL_LENGTH('dbo.Materials','TechnicalSpecification') IS NULL
    ALTER TABLE dbo.Materials ADD TechnicalSpecification NVARCHAR(MAX) NULL;

-- Missing columns for ProductionOrders
IF COL_LENGTH('dbo.ProductionOrders','Note') IS NULL
    ALTER TABLE dbo.ProductionOrders ADD Note NVARCHAR(MAX) NULL;
IF COL_LENGTH('dbo.ProductionOrders','PlannedCartons') IS NULL
    ALTER TABLE dbo.ProductionOrders ADD PlannedCartons INT NULL;
IF COL_LENGTH('dbo.ProductionOrders','StartDate') IS NULL
    ALTER TABLE dbo.ProductionOrders ADD StartDate DATETIME NULL;
IF COL_LENGTH('dbo.ProductionOrders','EndDate') IS NULL
    ALTER TABLE dbo.ProductionOrders ADD EndDate DATETIME NULL;

-- Missing columns for ProductionBatches
IF COL_LENGTH('dbo.ProductionBatches','PlannedQuantity') IS NULL
    ALTER TABLE dbo.ProductionBatches ADD PlannedQuantity DECIMAL(18,4) NULL;
IF COL_LENGTH('dbo.ProductionBatches','CreatedAt') IS NULL
    ALTER TABLE dbo.ProductionBatches ADD CreatedAt DATETIME NULL DEFAULT GETDATE();
IF COL_LENGTH('dbo.ProductionBatches','ExpiryDate') IS NULL
    ALTER TABLE dbo.ProductionBatches ADD ExpiryDate DATETIME NULL;
IF COL_LENGTH('dbo.ProductionBatches','EndTime') IS NULL
    ALTER TABLE dbo.ProductionBatches ADD EndTime DATETIME NULL;

IF OBJECT_ID('dbo.SystemAuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemAuditLog (
        LogId INT IDENTITY(1,1) PRIMARY KEY,
        TableName NVARCHAR(100),
        RecordId NVARCHAR(100),
        Action NVARCHAR(50),
        OldValue NVARCHAR(MAX),
        NewValue NVARCHAR(MAX),
        ChangedDate DATETIME DEFAULT GETDATE()
    );
END;
";

    await db.Database.ExecuteSqlRawAsync(sql);
}

static async Task EnsureTriggersAsync(GmpContext db)
{
    const string sql = @"
IF OBJECT_ID('dbo.trg_Audit_Materials', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_Materials ON dbo.Materials AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''Materials'', CAST(COALESCE(i.MaterialId,d.MaterialId) AS NVARCHAR(50)),
CASE WHEN i.MaterialId IS NOT NULL AND d.MaterialId IS NULL THEN ''Create''
     WHEN i.MaterialId IS NOT NULL AND d.MaterialId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.MaterialId IS NULL THEN NULL ELSE CONCAT(''Code='', d.MaterialCode, '';Name='', d.MaterialName) END,
CASE WHEN i.MaterialId IS NULL THEN NULL ELSE CONCAT(''Code='', i.MaterialCode, '';Name='', i.MaterialName) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.MaterialId = d.MaterialId; END');

IF OBJECT_ID('dbo.trg_Audit_ProductionOrders', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_ProductionOrders ON dbo.ProductionOrders AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''ProductionOrders'', CAST(COALESCE(i.OrderId,d.OrderId) AS NVARCHAR(50)),
CASE WHEN i.OrderId IS NOT NULL AND d.OrderId IS NULL THEN ''Create''
     WHEN i.OrderId IS NOT NULL AND d.OrderId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.OrderId IS NULL THEN NULL ELSE CONCAT(''Code='', d.OrderCode, '';Status='', d.Status) END,
CASE WHEN i.OrderId IS NULL THEN NULL ELSE CONCAT(''Code='', i.OrderCode, '';Status='', i.Status) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.OrderId = d.OrderId; END');

IF OBJECT_ID('dbo.trg_Audit_InventoryLots', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_InventoryLots ON dbo.InventoryLots AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''InventoryLots'', CAST(COALESCE(i.LotId,d.LotId) AS NVARCHAR(50)),
CASE WHEN i.LotId IS NOT NULL AND d.LotId IS NULL THEN ''Create''
     WHEN i.LotId IS NOT NULL AND d.LotId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.LotId IS NULL THEN NULL ELSE CONCAT(''Lot='', d.LotNumber, '';Qty='', d.QuantityCurrent) END,
CASE WHEN i.LotId IS NULL THEN NULL ELSE CONCAT(''Lot='', i.LotNumber, '';Qty='', i.QuantityCurrent) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.LotId = d.LotId; END');

IF OBJECT_ID('dbo.trg_Audit_Equipments', 'TR') IS NULL
EXEC('CREATE TRIGGER dbo.trg_Audit_Equipments ON dbo.Equipments AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON;
INSERT INTO dbo.SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
SELECT ''Equipments'', CAST(COALESCE(i.EquipmentId,d.EquipmentId) AS NVARCHAR(50)),
CASE WHEN i.EquipmentId IS NOT NULL AND d.EquipmentId IS NULL THEN ''Create''
     WHEN i.EquipmentId IS NOT NULL AND d.EquipmentId IS NOT NULL THEN ''Update''
     ELSE ''Delete'' END,
CASE WHEN d.EquipmentId IS NULL THEN NULL ELSE CONCAT(''Code='', d.EquipmentCode) END,
CASE WHEN i.EquipmentId IS NULL THEN NULL ELSE CONCAT(''Code='', i.EquipmentCode) END,
GETDATE()
FROM inserted i FULL OUTER JOIN deleted d ON i.EquipmentId = d.EquipmentId; END');
";

    await db.Database.ExecuteSqlRawAsync(sql);
}

static async Task EnsureAreaSeedAsync(GmpContext db)
{
    if (!await db.ProductionAreas.AnyAsync())
    {
        db.ProductionAreas.AddRange(
            new ProductionArea { AreaCode = "PHA-CHE", AreaName = "Phòng pha chế", Description = "Khu vực pha chế nguyên liệu" },
            new ProductionArea { AreaCode = "PHONG-CAN", AreaName = "Phòng cân", Description = "Khu vực cân định lượng" },
            new ProductionArea { AreaCode = "TRON-KHO", AreaName = "Phòng trộn khô", Description = "Khu vực trộn đồng nhất" }
        );
        await db.SaveChangesAsync();
    }

    var areaMap = await db.ProductionAreas.ToDictionaryAsync(a => a.AreaCode, a => a.AreaId);
    var equipments = await db.Equipments.ToListAsync();
    foreach (var e in equipments)
    {
        if (string.IsNullOrWhiteSpace(e.TechnicalSpecification) || string.IsNullOrWhiteSpace(e.UsagePurpose) || e.AreaId == null)
        {
            switch (e.EquipmentCode)
            {
                case "IW2-60":
                    e.TechnicalSpecification = "60 kg; 5 g";
                    e.UsagePurpose = "Cân nguyên liệu và tá dược";
                    e.AreaId = areaMap.GetValueOrDefault("PHONG-CAN");
                    break;
                case "PMA-5000":
                    e.TechnicalSpecification = "5 kg; 0,1 g";
                    e.UsagePurpose = "Cân tá dược";
                    e.AreaId = areaMap.GetValueOrDefault("PHONG-CAN");
                    break;
                case "AD-LP-200":
                    e.TechnicalSpecification = "200 kg/mẻ";
                    e.UsagePurpose = "Trộn đồng nhất";
                    e.AreaId = areaMap.GetValueOrDefault("TRON-KHO");
                    break;
                case "NJP-1200 D":
                case "EQP-CAP-01":
                    e.TechnicalSpecification = "72.000 viên/giờ";
                    e.UsagePurpose = "Cấp thuốc vào nang";
                    e.AreaId = areaMap.GetValueOrDefault("PHA-CHE");
                    break;
                default:
                    e.TechnicalSpecification ??= "Theo biểu mẫu GMP";
                    e.UsagePurpose ??= "Theo công đoạn";
                    e.AreaId ??= areaMap.Values.FirstOrDefault();
                    break;
            }
        }
    }
    await db.SaveChangesAsync();
}

static async Task EnsureUserSeedAsync(GmpContext db)
{
    if (!await db.AppUsers.AnyAsync())
    {
        db.AppUsers.AddRange(
            new AppUser { Username = "admin", FullName = "Admin Hệ Thống", Role = "Admin", IsActive = true, PasswordHash = "$2b$11$hyVSDA5K2Qg1FVUosjSk4e76FBcJhE7DbNG/KDELUBotFzcSt5xIW", PinCode = "123456" },
            new AppUser { Username = "qc01", FullName = "Trần Thị Kiểm Tra", Role = "QA_QC", IsActive = true, PasswordHash = "$2b$11$f1zats7FFnLII0ru7JfcZu0uJsbE7DEsMLXooia8ZfAlbsj3bZKWK", PinCode = "123456" },
            new AppUser { Username = "op01", FullName = "Nguyễn Văn Công Nhân", Role = "Operator", IsActive = true, PasswordHash = "$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW", PinCode = "123456" },
            new AppUser { Username = "mgr01", FullName = "Lê Quang Quản Lý", Role = "ProductionManager", IsActive = true, PasswordHash = "$2b$11$s5NvxgDNGDX/ag6E2gsIe.cVEeFE16YCCYZkBItX/lRZvrEQxdtzW", PinCode = "123456" }
        );
        await db.SaveChangesAsync();
        Console.WriteLine("[BACKEND] Default users seeded successfully.");
    }
}
