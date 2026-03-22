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

var builder = WebApplication.CreateBuilder(args);

// ============================================================
// 1. CONTROLLERS + JSON
// ============================================================
builder.Services.AddControllers(options =>
{
    // Áp dụng [Authorize] cho toàn bộ API — chỉ AllowAnonymous mới bypass được
    options.Filters.Add(new AuthorizeFilter());
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    options.JsonSerializerOptions.PropertyNamingPolicy = null;
});

// ============================================================
// 2. JWT AUTHENTICATION
// ============================================================
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? "GMP_WHO_Default_Secret_Key_Minimum_32_Characters_Long_123456789";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "gmp-api";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "gmp-frontend";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };
    options.Events = new JwtBearerEvents
    {
        OnChallenge = context =>
        {
            context.HandleResponse();
            context.Response.StatusCode = 401;
            context.Response.ContentType = "application/json";
            return context.Response.WriteAsync(
                "{\"success\":false,\"message\":\"Bạn chưa đăng nhập hoặc phiên làm việc đã hết hạn.\"}");
        },
        OnForbidden = context =>
        {
            context.Response.StatusCode = 403;
            context.Response.ContentType = "application/json";
            return context.Response.WriteAsync(
                "{\"success\":false,\"message\":\"Bạn không có quyền truy cập chức năng này.\"}");
        }
    };
});

builder.Services.AddAuthorization();

// ============================================================
// 3. CORS — cho phép frontend và mobile
// ============================================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy.WithOrigins(
                    "http://localhost:8080",   // Frontend DEV
                    "http://localhost:8081",   // Mobile DEV
                    "http://100.89.137.3:8080", // Frontend prod (Tailscale)
                    "http://100.89.137.3:8081"  // Mobile prod (Tailscale)
                )
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});

// ============================================================
// 4. DATABASE + UnitOfWork
// ============================================================
builder.Services.AddScoped<GMP_System.Interceptors.AuditLogInterceptor>();

builder.Services.AddDbContext<GmpContext>((sp, options) =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    var interceptor = sp.GetRequiredService<GMP_System.Interceptors.AuditLogInterceptor>();
    options.AddInterceptors(interceptor);
    options.UseSqlServer(connectionString);
});

builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// IHttpContextAccessor — cho AuditLogInterceptor lấy user từ JWT
builder.Services.AddHttpContextAccessor();

var app = builder.Build();


// ============================================================
// 5. SEED DATABASE
// ============================================================
using (var scope = app.Services.CreateScope())
{
    // ----- RETRY LOGIC FOR DATABASE CONNECTION -----
    int maxRetries = 10;
    int delay = 5000;
    for (int i = 0; i < maxRetries; i++)
    {
        try
        {
            var db = scope.ServiceProvider.GetRequiredService<GmpContext>();
            
            // ----- MANUAL MIGRATION: Đảm bảo có cột PasswordHash -----
            db.Database.ExecuteSqlRaw(@"
                IF NOT EXISTS (SELECT * FROM sys.columns 
                               WHERE object_id = OBJECT_ID(N'[AppUsers]') 
                               AND name = 'PasswordHash')
                BEGIN
                    ALTER TABLE AppUsers ADD PasswordHash NVARCHAR(MAX) NULL;
                END
            ");

            db.Database.EnsureCreated();
            break; // Success
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Database connection attempt {i + 1} failed: {ex.Message}");
            if (i == maxRetries - 1) throw;
            Thread.Sleep(delay);
        }
    }

    var dbFinal = scope.ServiceProvider.GetRequiredService<GmpContext>();

    // ----- ĐẢM BẢO CÁC USER MẶC ĐỊNH LUÔN TỒN TẠI -----
    Console.WriteLine("----- CHECKING DEFAULT USERS -----");
    
    void EnsureUser(string username, string fullName, string role, string password)
    {
        var user = dbFinal.AppUsers.FirstOrDefault(u => u.Username == username);
        if (user == null)
        {
            dbFinal.AppUsers.Add(new GMP_System.Entities.AppUser
            {
                Username = username,
                FullName = fullName,
                Role = role,
                IsActive = true,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                CreatedAt = DateTime.Now
            });
            Console.WriteLine($"Added missing user: {username}");
        }
        else
        {
            // Reset password để đảm bảo khớp tài liệu
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password);
            Console.WriteLine($"Reset password for user: {username}");
        }
    }

    EnsureUser("admin", "Quản trị viên", "Admin", "Admin@123");
    EnsureUser("qc01", "Trần Kiểm Tra", "QA_QC", "Qc@123456");
    EnsureUser("op01", "Nguyễn Công Nhân", "Operator", "Op@123456");

    dbFinal.SaveChanges();
    Console.WriteLine("----- SYSTEM SEEDING COMPLETE -----");

    // ----- SEED MATERIALS DATA (nếu chưa có) -----
    if (!dbFinal.Materials.Any())
    {
        var unit1 = new GMP_System.Entities.UnitOfMeasure { UomName = "Kilogram", Description = "Kilogram" };
        var unit2 = new GMP_System.Entities.UnitOfMeasure { UomName = "Gram", Description = "Gram" };
        var unit3 = new GMP_System.Entities.UnitOfMeasure { UomName = "Tablet", Description = "Tablet" };
        dbFinal.UnitOfMeasures.AddRange(unit1, unit2, unit3);
        dbFinal.SaveChanges();

        var material1 = new GMP_System.Entities.Material
        {
            MaterialCode = "MAT-001",
            MaterialName = "Paracetamol 500mg",
            Type = "RawMaterial",
            BaseUomId = unit3.UomId,
            IsActive = true,
            Description = "Active ingredient for pain relief",
            CreatedAt = DateTime.Now
        };
        var material2 = new GMP_System.Entities.Material
        {
            MaterialCode = "MAT-002",
            MaterialName = "Microcrystalline Cellulose",
            Type = "RawMaterial",
            BaseUomId = unit1.UomId,
            IsActive = true,
            Description = "Excipient binder",
            CreatedAt = DateTime.Now
        };
        var material3 = new GMP_System.Entities.Material
        {
            MaterialCode = "MAT-003",
            MaterialName = "Para Film",
            Type = "Packaging",
            BaseUomId = unit2.UomId,
            IsActive = true,
            Description = "Packaging film for blister packs",
            CreatedAt = DateTime.Now
        };
        dbFinal.Materials.AddRange(material1, material2, material3);
        dbFinal.SaveChanges();

        var recipe1 = new GMP_System.Entities.Recipe
        {
            MaterialId = material1.MaterialId,
            BatchSize = 1000,
            Status = "Draft",
            VersionNumber = 1,
            CreatedAt = DateTime.Now,
            EffectiveDate = DateTime.Now.AddDays(1),
            Note = "Initial draft"
        };
        dbFinal.Recipes.Add(recipe1);
        dbFinal.SaveChanges();

        dbFinal.RecipeBoms.Add(new GMP_System.Entities.RecipeBom
        {
            RecipeId = recipe1.RecipeId,
            MaterialId = material2.MaterialId,
            Quantity = 0.5m,
            UomId = unit1.UomId
        });
        dbFinal.RecipeBoms.Add(new GMP_System.Entities.RecipeBom
        {
            RecipeId = recipe1.RecipeId,
            MaterialId = material3.MaterialId,
            Quantity = 0.1m,
            UomId = unit2.UomId
        });

        var lot1 = new GMP_System.Entities.InventoryLot
        {
            MaterialId = material2.MaterialId,
            LotNumber = "LOT-MCC-001",
            QuantityCurrent = 100,
            ManufactureDate = DateTime.Now.AddMonths(-1),
            ExpiryDate = DateTime.Now.AddMonths(11),
            Qcstatus = "Released"
        };
        var lot2 = new GMP_System.Entities.InventoryLot
        {
            MaterialId = material3.MaterialId,
            LotNumber = "LOT-FILM-001",
            QuantityCurrent = 500,
            ManufactureDate = DateTime.Now.AddMonths(-2),
            ExpiryDate = DateTime.Now.AddMonths(10),
            Qcstatus = "Released"
        };
        dbFinal.InventoryLots.AddRange(lot1, lot2);
        dbFinal.SaveChanges();

        var order1 = new GMP_System.Entities.ProductionOrder
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
        dbFinal.ProductionOrders.Add(order1);
        dbFinal.SaveChanges();

        var batch1 = new GMP_System.Entities.ProductionBatch
        {
            OrderId = order1.OrderId,
            BatchNumber = "BATCH-PCM-001",
            ManufactureDate = DateTime.Now.AddDays(-7),
            EndTime = DateTime.Now.AddDays(-6),
            Status = "Completed"
        };
        dbFinal.ProductionBatches.Add(batch1);
        dbFinal.SaveChanges();

        dbFinal.MaterialUsages.Add(new GMP_System.Entities.MaterialUsage
        {
            BatchId = batch1.BatchId,
            InventoryLotId = lot1.LotId,
            ActualAmount = 50,
            Timestamp = DateTime.Now.AddDays(-7),
            Note = "Used in batch BATCH-PCM-001"
        });
        dbFinal.MaterialUsages.Add(new GMP_System.Entities.MaterialUsage
        {
            BatchId = batch1.BatchId,
            InventoryLotId = lot2.LotId,
            ActualAmount = 100,
            Timestamp = DateTime.Now.AddDays(-7),
            Note = "Used in batch BATCH-PCM-001"
        });

        dbFinal.SaveChanges();
    }
}

// ============================================================
// 6. MIDDLEWARE PIPELINE
// ============================================================
app.MapGet("/health", () => Results.Json(new { status = "healthy", timestamp = DateTime.UtcNow }))
   .AllowAnonymous();

app.UseCors("AllowFrontend");
app.UseHttpsRedirection();
app.UseAuthentication();   // PHẢI trước UseAuthorization
app.UseAuthorization();
app.MapControllers();

app.Run();
