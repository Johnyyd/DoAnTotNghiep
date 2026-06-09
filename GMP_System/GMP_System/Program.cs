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
            bool isNewlyCreated = db.Database.EnsureCreated();
            db.Database.ExecuteSqlRaw(@"
IF OBJECT_ID(N'dbo.SystemAuditLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemAuditLog
    (
        AuditId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SystemAuditLog PRIMARY KEY,
        TableName NVARCHAR(100) NOT NULL,
        RecordId NVARCHAR(100) NOT NULL,
        Action NVARCHAR(50) NOT NULL,
        OldValue NVARCHAR(MAX) NULL,
        NewValue NVARCHAR(MAX) NULL,
        ChangedBy INT NULL,
        ChangedDate DATETIME2 NOT NULL CONSTRAINT DF_SystemAuditLog_ChangedDate DEFAULT GETDATE()
    );
END;

IF COL_LENGTH(N'dbo.ProductionOrders', N'RecipeName') IS NULL
BEGIN
    ALTER TABLE dbo.ProductionOrders ADD RecipeName NVARCHAR(200) NULL;
END;

IF COL_LENGTH(N'dbo.Recipes', N'BatchUomId') IS NULL
BEGIN
    ALTER TABLE dbo.Recipes ADD BatchUomId INT NULL;
END;

IF OBJECT_ID(N'dbo.Recipes', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.UnitOfMeasure', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Recipes_BatchUom')
BEGIN
    EXEC(N'ALTER TABLE dbo.Recipes
    ADD CONSTRAINT FK_Recipes_BatchUom FOREIGN KEY (BatchUomId) REFERENCES dbo.UnitOfMeasure(UomId)');
END;

IF OBJECT_ID(N'dbo.Recipes', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.UnitOfMeasure', N'U') IS NOT NULL
BEGIN
    EXEC(N'UPDATE r
    SET BatchUomId = CASE
        WHEN m.BaseUomID IN (3, 10) THEN 10
        ELSE 9
    END
    FROM dbo.Recipes r
    LEFT JOIN dbo.Materials m ON r.MaterialID = m.MaterialID
    WHERE r.BatchUomId IS NULL');

    EXEC(N'UPDATE dbo.Recipes
    SET BatchUomId = 10
    WHERE (RecipeName LIKE N''%ống%'' OR Note LIKE N''%ml/%'')');
END;

IF COL_LENGTH(N'dbo.ProductionOrderBom', N'SelectedLotId') IS NULL
BEGIN
    ALTER TABLE dbo.ProductionOrderBom ADD SelectedLotId INT NULL;
END;

IF COL_LENGTH(N'dbo.InventoryLots', N'RetestDate') IS NOT NULL
BEGIN
    ALTER TABLE dbo.InventoryLots DROP COLUMN RetestDate;
END;

IF OBJECT_ID(N'dbo.InventoryLots', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ProductionOrderBom', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ProductionOrderBom_SelectedLot')
BEGIN
    ALTER TABLE dbo.ProductionOrderBom
    ADD CONSTRAINT FK_ProductionOrderBom_SelectedLot FOREIGN KEY (SelectedLotId) REFERENCES dbo.InventoryLots(LotId);
END;
");
            
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

                    var scripts = new[] { "SystemAudit.sql", "full_seed.sql", "BackupRestoreJobs.sql" };
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
                                    using (var command = db.Database.GetDbConnection().CreateCommand())
                                    {
                                        command.CommandText = trimmedBatch;
                                        command.CommandType = System.Data.CommandType.Text;
                                        if (command.Connection!.State != System.Data.ConnectionState.Open)
                                        {
                                            command.Connection!.Open();
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


