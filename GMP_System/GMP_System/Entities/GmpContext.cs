using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace GMP_System.Entities;

public partial class GmpContext : DbContext
{
    public GmpContext()
    {
    }

    public GmpContext(DbContextOptions<GmpContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AppUser> AppUsers { get; set; } = null!;

    public virtual DbSet<BatchProcessLog> BatchProcessLogs { get; set; } = null!;

    public virtual DbSet<Equipment> Equipments { get; set; } = null!;

    public virtual DbSet<InventoryLot> InventoryLots { get; set; } = null!;

    public virtual DbSet<Material> Materials { get; set; } = null!;

    public virtual DbSet<MaterialUsage> MaterialUsages { get; set; } = null!;

    public virtual DbSet<ProductionBatch> ProductionBatches { get; set; } = null!;

    public virtual DbSet<ProductionOrder> ProductionOrders { get; set; } = null!;

    public virtual DbSet<ProductionArea> ProductionAreas { get; set; } = null!;

    public virtual DbSet<Recipe> Recipes { get; set; } = null!;

    public virtual DbSet<RecipeBom> RecipeBoms { get; set; } = null!;

    public virtual DbSet<RecipeRouting> RecipeRoutings { get; set; } = null!;


    public virtual DbSet<UnitOfMeasure> UnitOfMeasures { get; set; } = null!;

    public virtual DbSet<UomConversion> UomConversions { get; set; } = null!;

    public virtual DbSet<StepParameter> StepParameters { get; set; } = null!;

    public virtual DbSet<BatchProcessParameterValue> BatchProcessParameterValues { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__AppUsers__1788CCAC14F8EE93");

            entity.HasIndex(e => e.Username, "UQ__AppUsers__536C85E4B8A21C8B").IsUnique();

            entity.Property(e => e.UserId).HasColumnName("UserID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.FullName).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Role).HasMaxLength(20);
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.PinCode)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasDefaultValue("000000");
            entity.Property(e => e.LastLogin).HasColumnType("datetime2");
        });

        modelBuilder.Entity<BatchProcessLog>(entity =>
        {
            entity.HasKey(e => e.LogId).HasName("PK__BatchPro__5E5499A811E7D688");

            entity.ToTable(tb => tb.HasTrigger("trg_Check_Equipment_Status"));

            entity.Property(e => e.LogId).HasColumnName("LogID");
            entity.Property(e => e.BatchId).HasColumnName("BatchID");
            entity.Property(e => e.EquipmentId).HasColumnName("EquipmentID");
            entity.Property(e => e.OperatorId).HasColumnName("OperatorID");
            entity.Property(e => e.ParametersData).HasColumnType("nvarchar(max)");
            entity.Property(e => e.ResultStatus).HasMaxLength(50);
            entity.Property(e => e.RoutingId).HasColumnName("RoutingID");

            entity.HasOne(d => d.Batch).WithMany(p => p.BatchProcessLogs)
                .HasForeignKey(d => d.BatchId)
                .HasConstraintName("FK__BatchProc__Batch__7C4F7684");

            entity.HasOne(d => d.Equipment).WithMany(p => p.BatchProcessLogs)
                .HasForeignKey(d => d.EquipmentId)
                .HasConstraintName("FK__BatchProc__Equip__7E37BEF6");

            entity.HasOne(d => d.Routing).WithMany(p => p.BatchProcessLogs)
                .HasForeignKey(d => d.RoutingId)
                .HasConstraintName("FK__BatchProc__Routi__7D439ABD");

            entity.HasOne(d => d.Operator).WithMany(p => p.BatchProcessLogOperators)
                .HasForeignKey(d => d.OperatorId)
                .HasConstraintName("FK_BatchProcessLog_Operator");

            entity.HasOne(d => d.VerifiedBy).WithMany(p => p.BatchProcessLogVerifiers)
                .HasForeignKey(d => d.VerifiedById)
                .HasConstraintName("FK_BatchProcessLog_Verifier");
        });

        modelBuilder.Entity<StepParameter>(entity =>
        {
            entity.HasKey(e => e.ParameterId);
            entity.Property(e => e.ParameterId).HasColumnName("ParameterId");
            entity.Property(e => e.RoutingId).HasColumnName("RoutingId");
            entity.Property(e => e.ParameterName).HasMaxLength(100);
            entity.Property(e => e.Unit).HasMaxLength(50);
            entity.Property(e => e.MinValue).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.MaxValue).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.IsCritical).HasDefaultValue(true);

            entity.HasOne(d => d.Routing).WithMany(p => p.StepParameters)
                .HasForeignKey(d => d.RoutingId)
                .HasConstraintName("FK_StepParameter_Routing");
        });

        modelBuilder.Entity<BatchProcessParameterValue>(entity =>
        {
            entity.HasKey(e => e.ValueId);
            entity.Property(e => e.ValueId).HasColumnName("ValueId");
            entity.Property(e => e.LogId).HasColumnName("LogId");
            entity.Property(e => e.ParameterId).HasColumnName("ParameterId");
            entity.Property(e => e.ActualValue).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.RecordedDate).HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.Log).WithMany(p => p.ParameterValues)
                .HasForeignKey(d => d.LogId)
                .HasConstraintName("FK_ParamValue_Log");

            entity.HasOne(d => d.Parameter).WithMany(p => p.ParameterValues)
                .HasForeignKey(d => d.ParameterId)
                .HasConstraintName("FK_ParamValue_Parameter");
        });

        modelBuilder.Entity<Equipment>(entity =>
        {
            entity.HasKey(e => e.EquipmentId).HasName("PK__Equipmen__34474599F11FEE84");

            entity.ToTable(tb => tb.HasTrigger("trg_Audit_Equipments"));

            entity.HasIndex(e => e.EquipmentCode, "UQ__Equipmen__09E4417E23FBF8F4").IsUnique();

            entity.Property(e => e.EquipmentId).HasColumnName("EquipmentID");
            entity.Property(e => e.EquipmentCode)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.EquipmentName).HasMaxLength(200);
            entity.Property(e => e.TechnicalSpecification).HasMaxLength(300);
            entity.Property(e => e.UsagePurpose).HasMaxLength(300);
            entity.Property(e => e.AreaId).HasColumnName("AreaId");


            entity.HasOne(d => d.Area).WithMany(p => p.Equipments)
                .HasForeignKey(d => d.AreaId)
                .HasConstraintName("FK_Equipments_ProductionAreas");
        });

        modelBuilder.Entity<InventoryLot>(entity =>
        {
            entity.HasKey(e => e.LotId);

            entity.ToTable(tb => tb.HasTrigger("trg_Audit_InventoryLots"));

            entity.Property(e => e.LotId).HasColumnName("LotId");
            entity.Property(e => e.LotNumber)
                .HasMaxLength(50)
                .IsUnicode(false);
            
            // Nếu dùng QCNumber trong code, ánh xạ tạm vào LotNumber hoặc để trống nếu DB không có.
            // Trong Schema.sql chỉ có LotNumber và QCStatus.
            // Tôi sẽ bỏ QCNumber mapping nếu DB không có để tránh lỗi 207.
            
            entity.Property(e => e.MaterialId).HasColumnName("MaterialId");

            entity.Property(e => e.QuantityCurrent)
                .HasColumnName("QuantityCurrent")
                .HasColumnType("decimal(18, 4)");

            entity.Property(e => e.QCStatus)
                .HasMaxLength(50)
                .HasColumnName("QCStatus");

            entity.HasOne(d => d.Material).WithMany(p => p.InventoryLots)
                .HasForeignKey(d => d.MaterialId);
        });

        modelBuilder.Entity<Material>(entity =>
        {
            entity.HasKey(e => e.MaterialId).HasName("PK__Material__C50613177C517D7B");

            entity.ToTable(tb => tb.HasTrigger("trg_Audit_Materials"));

            entity.HasIndex(e => e.MaterialCode, "UQ__Material__170C54BAB161407D").IsUnique();

            entity.Property(e => e.MaterialId).HasColumnName("MaterialID");
            entity.Property(e => e.BaseUomId).HasColumnName("BaseUomID");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.TechnicalSpecification)
                .HasMaxLength(500)
                .HasColumnName("TechnicalSpecification");
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.MaterialCode)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.MaterialName).HasMaxLength(200);
            entity.Property(e => e.Type).HasMaxLength(50);

            entity.HasOne(d => d.BaseUom).WithMany(p => p.Materials)
                .HasForeignKey(d => d.BaseUomId)
                .HasConstraintName("FK__Materials__BaseU__4E88ABD4");
        });

        modelBuilder.Entity<MaterialUsage>(entity =>
        {
            entity.HasKey(e => e.UsageId).HasName("PK__Material__29B197C0A60A3ED1");

            entity.ToTable("MaterialUsage", tb =>
                {
                    tb.HasTrigger("trg_Check_Material_QC");
                    tb.HasTrigger("trg_Validate_Material_Usage");
                });

            entity.Property(e => e.UsageId).HasColumnName("UsageID");
            entity.Property(e => e.ActualAmount).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.BatchId).HasColumnName("BatchID");
            entity.Property(e => e.InventoryLotId).HasColumnName("InventoryLotID");
            entity.Property(e => e.Note).HasMaxLength(200);
            entity.Property(e => e.PlannedAmount).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.Timestamp).HasDefaultValueSql("(getdate())");

            entity.HasOne(d => d.Batch).WithMany(p => p.MaterialUsages)
                .HasForeignKey(d => d.BatchId)
                .HasConstraintName("FK__MaterialU__Batch__05D8E0BE");

            entity.HasOne(d => d.DispensedByNavigation).WithMany(p => p.MaterialUsages)
                .HasForeignKey(d => d.DispensedBy)
                .HasConstraintName("FK_Usage_User");

            entity.HasOne(d => d.InventoryLot).WithMany(p => p.MaterialUsages)
                .HasForeignKey(d => d.InventoryLotId)
                .HasConstraintName("FK__MaterialU__Inven__06CD04F7");
        });

        modelBuilder.Entity<ProductionBatch>(entity =>
        {
            entity.HasKey(e => e.BatchId).HasName("PK__Producti__5D55CE38408FD6AE");

            entity.HasIndex(e => e.BatchNumber, "UQ__Producti__F869ED6D7BFC6457").IsUnique();

            entity.Property(e => e.BatchId).HasColumnName("BatchID");
            entity.Property(e => e.BatchNumber)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CurrentStep).HasDefaultValue(0);
            entity.Property(e => e.ManufactureDate).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.OrderId).HasColumnName("OrderID");
            entity.Property(e => e.Status)
                .HasMaxLength(50)
                .HasDefaultValue("Queued");

            entity.HasOne(d => d.Order).WithMany(p => p.ProductionBatches)
                .HasForeignKey(d => d.OrderId)
                .HasConstraintName("FK__Productio__Order__76969D2E");
        });

        modelBuilder.Entity<ProductionOrder>(entity =>
        {
            entity.HasKey(e => e.OrderId).HasName("PK__Producti__C3905BAF770F7793");

            entity.ToTable(tb => tb.HasTrigger("trg_Audit_ProductionOrders"));

            entity.HasIndex(e => e.OrderCode, "UQ__Producti__999B5229EBD49113").IsUnique();

            entity.Property(e => e.OrderId).HasColumnName("OrderID");
            entity.Property(e => e.ActualQuantity).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())");
            entity.Property(e => e.OrderCode)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.PlannedQuantity).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.RecipeId).HasColumnName("RecipeID");
            entity.Property(e => e.Status).HasMaxLength(50);

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.ProductionOrders)
                .HasForeignKey(d => d.CreatedBy)
                .HasConstraintName("FK_Orders_User");

            entity.HasOne(d => d.Recipe).WithMany(p => p.ProductionOrders)
                .HasForeignKey(d => d.RecipeId)
                .HasConstraintName("FK__Productio__Recip__70DDC3D8");
        });

        modelBuilder.Entity<Recipe>(entity =>
        {
            entity.HasKey(e => e.RecipeId).HasName("PK__Recipes__FDD988D03D4E35FD");

            entity.ToTable(tb =>
                {
                    tb.HasTrigger("trg_Prevent_Edit_Approved_Recipe");
                    tb.HasTrigger("trg_Recipes_Audit");
                });

            entity.HasIndex(e => new { e.MaterialId, e.VersionNumber }, "UQ_Recipe_Version").IsUnique();

            entity.Property(e => e.RecipeId).HasColumnName("RecipeID");
            entity.Property(e => e.BatchSize).HasColumnType("decimal(18, 4)");
            entity.Property(e => e.MaterialId).HasColumnName("MaterialID");
            entity.Property(e => e.Status).HasMaxLength(50);

            entity.HasOne(d => d.ApprovedByNavigation).WithMany(p => p.Recipes)
                .HasForeignKey(d => d.ApprovedBy)
                .HasConstraintName("FK_Recipes_User");

            entity.HasOne(d => d.Material).WithMany(p => p.Recipes)
                .HasForeignKey(d => d.MaterialId)
                .HasConstraintName("FK__Recipes__Materia__628FA481");
        });

        modelBuilder.Entity<RecipeBom>(entity =>
        {
            entity.HasKey(e => e.BomId).HasName("PK__RecipeBO__7D5F6A17C1D35BE0");

            entity.ToTable("RecipeBOM");

            entity.Property(e => e.BomId).HasColumnName("BomID");
            entity.Property(e => e.MaterialId).HasColumnName("MaterialID");
            entity.Property(e => e.Note).HasMaxLength(200);
            entity.Property(e => e.Quantity).HasColumnType("decimal(18, 6)");
            entity.Property(e => e.RecipeId).HasColumnName("RecipeID");
            entity.Property(e => e.UomId).HasColumnName("UomID");
            entity.Property(e => e.WastePercentage)
                .HasDefaultValue(0m)
                .HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.Material).WithMany(p => p.RecipeBoms)
                .HasForeignKey(d => d.MaterialId)
                .HasConstraintName("FK__RecipeBOM__Mater__6754599E");

            entity.HasOne(d => d.Recipe).WithMany(p => p.RecipeBoms)
                .HasForeignKey(d => d.RecipeId)
                .HasConstraintName("FK__RecipeBOM__Recip__66603565");

            entity.HasOne(d => d.Uom).WithMany(p => p.RecipeBoms)
                .HasForeignKey(d => d.UomId)
                .HasConstraintName("FK__RecipeBOM__UomID__68487DD7");
        });

        modelBuilder.Entity<RecipeRouting>(entity =>
        {
            entity.HasKey(e => e.RoutingId).HasName("PK__RecipeRo__A763F8A8F9EEA6DD");

            entity.ToTable("RecipeRouting");

            entity.Property(e => e.RoutingId).HasColumnName("RoutingID");
            entity.Property(e => e.DefaultEquipmentId).HasColumnName("DefaultEquipmentID");
            entity.Property(e => e.RecipeId).HasColumnName("RecipeID");
            entity.Property(e => e.OrderId).HasColumnName("OrderID");
            entity.Property(e => e.StepName).HasMaxLength(200);
            entity.Property(e => e.NumberOfRouting).HasDefaultValue(1);

            entity.HasOne(d => d.DefaultEquipment).WithMany(p => p.RecipeRoutings)
                .HasForeignKey(d => d.DefaultEquipmentId)
                .HasConstraintName("FK__RecipeRou__Defau__6D0D32F4");

            entity.HasOne(d => d.Recipe).WithMany(p => p.RecipeRoutings)
                .HasForeignKey(d => d.RecipeId)
                .HasConstraintName("FK__RecipeRou__Recip__6C190EBB");

            entity.HasOne(d => d.Order).WithMany(p => p.RecipeRoutings)
                .HasForeignKey(d => d.OrderId)
                .HasConstraintName("FK_RecipeRouting_ProductionOrders");
        });


        modelBuilder.Entity<ProductionArea>(entity =>
        {
            entity.HasKey(e => e.AreaId).HasName("PK__Producti__70B82028");

            entity.ToTable("ProductionAreas");

            entity.HasIndex(e => e.AreaCode, "UQ_ProductionAreas_AreaCode").IsUnique();

            entity.Property(e => e.AreaId).HasColumnName("AreaId");
            entity.Property(e => e.AreaCode)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.AreaName).HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(500);
        });

        modelBuilder.Entity<UnitOfMeasure>(entity =>
        {
            entity.HasKey(e => e.UomId).HasName("PK__UnitOfMe__F6F8D59EA16C24B6");

            entity.ToTable("UnitOfMeasure");

            entity.Property(e => e.UomId).HasColumnName("UomID");
            entity.Property(e => e.Description).HasMaxLength(200);
            entity.Property(e => e.UomName).HasMaxLength(50);
        });

        modelBuilder.Entity<UomConversion>(entity =>
        {
            entity.HasKey(e => e.ConversionId).HasName("PK__UomConve__A7A07F935A520669");

            entity.HasIndex(e => new { e.FromUomId, e.ToUomId }, "UQ_Conversion").IsUnique();

            entity.Property(e => e.ConversionId).HasColumnName("ConversionID");
            entity.Property(e => e.ConversionFactor)
                .HasColumnType("decimal(18, 6)")
                .HasColumnName("ConversionFactor");
            entity.Property(e => e.FromUomId).HasColumnName("FromUomID");
            entity.Property(e => e.ToUomId).HasColumnName("ToUomID");
            entity.Property(e => e.Note).HasMaxLength(200);

            entity.HasOne(d => d.FromUom).WithMany(p => p.UomConversionFromUoms)
                .HasForeignKey(d => d.FromUomId)
                .HasConstraintName("FK__UomConver__FromU__5DCAEF64");

            entity.HasOne(d => d.ToUom).WithMany(p => p.UomConversionToUoms)
                .HasForeignKey(d => d.ToUomId)
                .HasConstraintName("FK__UomConver__ToUom__5EBF139D");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
