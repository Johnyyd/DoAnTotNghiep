using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GMP_System.GMP_System.GMP_System.Entities.Migrations
{
    /// <inheritdoc />
    public partial class Init : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AppUsers",
                columns: table => new
                {
                    UserID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Username = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Role = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: true, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    LastLogin = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PinCode = table.Column<string>(type: "varchar(6)", unicode: false, maxLength: 6, nullable: true, defaultValue: "000000")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__AppUsers__1788CCAC14F8EE93", x => x.UserID);
                });

            migrationBuilder.CreateTable(
                name: "ProductionAreas",
                columns: table => new
                {
                    AreaId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AreaCode = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    AreaName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Producti__70B82028", x => x.AreaId);
                });

            migrationBuilder.CreateTable(
                name: "UnitOfMeasure",
                columns: table => new
                {
                    UomID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UomName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__UnitOfMe__F6F8D59EA16C24B6", x => x.UomID);
                });

            migrationBuilder.CreateTable(
                name: "Equipments",
                columns: table => new
                {
                    EquipmentID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EquipmentCode = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    EquipmentName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    TechnicalSpecification = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    UsagePurpose = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    AreaId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Equipmen__34474599F11FEE84", x => x.EquipmentID);
                    table.ForeignKey(
                        name: "FK_Equipments_ProductionAreas",
                        column: x => x.AreaId,
                        principalTable: "ProductionAreas",
                        principalColumn: "AreaId");
                });

            migrationBuilder.CreateTable(
                name: "Materials",
                columns: table => new
                {
                    MaterialID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MaterialCode = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    MaterialName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    BaseUomID = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: true, defaultValue: true),
                    TechnicalSpecification = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Material__C50613177C517D7B", x => x.MaterialID);
                    table.ForeignKey(
                        name: "FK__Materials__BaseU__4E88ABD4",
                        column: x => x.BaseUomID,
                        principalTable: "UnitOfMeasure",
                        principalColumn: "UomID");
                });

            migrationBuilder.CreateTable(
                name: "UomConversions",
                columns: table => new
                {
                    ConversionID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FromUomID = table.Column<int>(type: "int", nullable: true),
                    ToUomID = table.Column<int>(type: "int", nullable: true),
                    ConversionFactor = table.Column<decimal>(type: "decimal(18,6)", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__UomConve__A7A07F935A520669", x => x.ConversionID);
                    table.ForeignKey(
                        name: "FK__UomConver__FromU__5DCAEF64",
                        column: x => x.FromUomID,
                        principalTable: "UnitOfMeasure",
                        principalColumn: "UomID");
                    table.ForeignKey(
                        name: "FK__UomConver__ToUom__5EBF139D",
                        column: x => x.ToUomID,
                        principalTable: "UnitOfMeasure",
                        principalColumn: "UomID");
                });

            migrationBuilder.CreateTable(
                name: "InventoryLots",
                columns: table => new
                {
                    LotId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MaterialId = table.Column<int>(type: "int", nullable: true),
                    LotNumber = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    QuantityCurrent = table.Column<decimal>(type: "decimal(18,4)", nullable: false),
                    ManufactureDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    QCStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    SupplierName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InventoryLots", x => x.LotId);
                    table.ForeignKey(
                        name: "FK_InventoryLots_Materials_MaterialId",
                        column: x => x.MaterialId,
                        principalTable: "Materials",
                        principalColumn: "MaterialID");
                });

            migrationBuilder.CreateTable(
                name: "Recipes",
                columns: table => new
                {
                    RecipeID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MaterialID = table.Column<int>(type: "int", nullable: true),
                    VersionNumber = table.Column<int>(type: "int", nullable: false),
                    BatchSize = table.Column<decimal>(type: "decimal(18,4)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ApprovedBy = table.Column<int>(type: "int", nullable: true),
                    ApprovedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EffectiveDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Recipes__FDD988D03D4E35FD", x => x.RecipeID);
                    table.ForeignKey(
                        name: "FK_Recipes_User",
                        column: x => x.ApprovedBy,
                        principalTable: "AppUsers",
                        principalColumn: "UserID");
                    table.ForeignKey(
                        name: "FK__Recipes__Materia__628FA481",
                        column: x => x.MaterialID,
                        principalTable: "Materials",
                        principalColumn: "MaterialID");
                });

            migrationBuilder.CreateTable(
                name: "ProductionOrders",
                columns: table => new
                {
                    OrderID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OrderCode = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    RecipeID = table.Column<int>(type: "int", nullable: true),
                    PlannedQuantity = table.Column<decimal>(type: "decimal(18,4)", nullable: false),
                    ActualQuantity = table.Column<decimal>(type: "decimal(18,4)", nullable: true),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    PlannedCartons = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Producti__C3905BAF770F7793", x => x.OrderID);
                    table.ForeignKey(
                        name: "FK_Orders_User",
                        column: x => x.CreatedBy,
                        principalTable: "AppUsers",
                        principalColumn: "UserID");
                    table.ForeignKey(
                        name: "FK__Productio__Recip__70DDC3D8",
                        column: x => x.RecipeID,
                        principalTable: "Recipes",
                        principalColumn: "RecipeID");
                });

            migrationBuilder.CreateTable(
                name: "RecipeBOM",
                columns: table => new
                {
                    BomID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RecipeID = table.Column<int>(type: "int", nullable: true),
                    MaterialID = table.Column<int>(type: "int", nullable: true),
                    Quantity = table.Column<decimal>(type: "decimal(18,6)", nullable: false),
                    UomID = table.Column<int>(type: "int", nullable: true),
                    WastePercentage = table.Column<decimal>(type: "decimal(5,2)", nullable: true, defaultValue: 0m),
                    Note = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__RecipeBO__7D5F6A17C1D35BE0", x => x.BomID);
                    table.ForeignKey(
                        name: "FK__RecipeBOM__Mater__6754599E",
                        column: x => x.MaterialID,
                        principalTable: "Materials",
                        principalColumn: "MaterialID");
                    table.ForeignKey(
                        name: "FK__RecipeBOM__Recip__66603565",
                        column: x => x.RecipeID,
                        principalTable: "Recipes",
                        principalColumn: "RecipeID");
                    table.ForeignKey(
                        name: "FK__RecipeBOM__UomID__68487DD7",
                        column: x => x.UomID,
                        principalTable: "UnitOfMeasure",
                        principalColumn: "UomID");
                });

            migrationBuilder.CreateTable(
                name: "ProductionBatches",
                columns: table => new
                {
                    BatchID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    OrderID = table.Column<int>(type: "int", nullable: true),
                    BatchNumber = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    ManufactureDate = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    EndTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CurrentStep = table.Column<int>(type: "int", nullable: true, defaultValue: 0),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true, defaultValue: "Queued"),
                    PlannedQuantity = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Producti__5D55CE38408FD6AE", x => x.BatchID);
                    table.ForeignKey(
                        name: "FK__Productio__Order__76969D2E",
                        column: x => x.OrderID,
                        principalTable: "ProductionOrders",
                        principalColumn: "OrderID");
                });

            migrationBuilder.CreateTable(
                name: "RecipeRouting",
                columns: table => new
                {
                    RoutingID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RecipeID = table.Column<int>(type: "int", nullable: true),
                    StepNumber = table.Column<int>(type: "int", nullable: false),
                    StepName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    NumberOfRouting = table.Column<int>(type: "int", nullable: true, defaultValue: 1),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    EstimatedTimeMinutes = table.Column<int>(type: "int", nullable: true),
                    DefaultEquipmentID = table.Column<int>(type: "int", nullable: true),
                    MaterialId = table.Column<int>(type: "int", nullable: true),
                    AreaId = table.Column<int>(type: "int", nullable: true),
                    CleanlinessStatus = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    StandardTemperature = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    StandardHumidity = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    StandardPressure = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    StabilityStatus = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SetTemperature = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    SetTimeMinutes = table.Column<int>(type: "int", nullable: true),
                    OrderID = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__RecipeRo__A763F8A8F9EEA6DD", x => x.RoutingID);
                    table.ForeignKey(
                        name: "FK_RecipeRouting_Materials_MaterialId",
                        column: x => x.MaterialId,
                        principalTable: "Materials",
                        principalColumn: "MaterialID");
                    table.ForeignKey(
                        name: "FK_RecipeRouting_ProductionAreas_AreaId",
                        column: x => x.AreaId,
                        principalTable: "ProductionAreas",
                        principalColumn: "AreaId");
                    table.ForeignKey(
                        name: "FK_RecipeRouting_ProductionOrders",
                        column: x => x.OrderID,
                        principalTable: "ProductionOrders",
                        principalColumn: "OrderID");
                    table.ForeignKey(
                        name: "FK__RecipeRou__Defau__6D0D32F4",
                        column: x => x.DefaultEquipmentID,
                        principalTable: "Equipments",
                        principalColumn: "EquipmentID");
                    table.ForeignKey(
                        name: "FK__RecipeRou__Recip__6C190EBB",
                        column: x => x.RecipeID,
                        principalTable: "Recipes",
                        principalColumn: "RecipeID");
                });

            migrationBuilder.CreateTable(
                name: "MaterialUsage",
                columns: table => new
                {
                    UsageID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BatchID = table.Column<int>(type: "int", nullable: true),
                    InventoryLotID = table.Column<int>(type: "int", nullable: true),
                    PlannedAmount = table.Column<decimal>(type: "decimal(18,4)", nullable: true),
                    ActualAmount = table.Column<decimal>(type: "decimal(18,4)", nullable: false),
                    UsedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DispensedBy = table.Column<int>(type: "int", nullable: true),
                    Note = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Timestamp = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Material__29B197C0A60A3ED1", x => x.UsageID);
                    table.ForeignKey(
                        name: "FK_Usage_User",
                        column: x => x.DispensedBy,
                        principalTable: "AppUsers",
                        principalColumn: "UserID");
                    table.ForeignKey(
                        name: "FK__MaterialU__Batch__05D8E0BE",
                        column: x => x.BatchID,
                        principalTable: "ProductionBatches",
                        principalColumn: "BatchID");
                    table.ForeignKey(
                        name: "FK__MaterialU__Inven__06CD04F7",
                        column: x => x.InventoryLotID,
                        principalTable: "InventoryLots",
                        principalColumn: "LotId");
                });

            migrationBuilder.CreateTable(
                name: "BatchProcessLogs",
                columns: table => new
                {
                    LogID = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BatchID = table.Column<int>(type: "int", nullable: true),
                    RoutingID = table.Column<int>(type: "int", nullable: true),
                    EquipmentID = table.Column<int>(type: "int", nullable: true),
                    OperatorID = table.Column<int>(type: "int", nullable: true),
                    StartTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EndTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ResultStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ParametersData = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    VerifiedById = table.Column<int>(type: "int", nullable: true),
                    VerifiedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsDeviation = table.Column<bool>(type: "bit", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NumberOfRouting = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__BatchPro__5E5499A811E7D688", x => x.LogID);
                    table.ForeignKey(
                        name: "FK_BatchProcessLog_Operator",
                        column: x => x.OperatorID,
                        principalTable: "AppUsers",
                        principalColumn: "UserID");
                    table.ForeignKey(
                        name: "FK_BatchProcessLog_Verifier",
                        column: x => x.VerifiedById,
                        principalTable: "AppUsers",
                        principalColumn: "UserID");
                    table.ForeignKey(
                        name: "FK__BatchProc__Batch__7C4F7684",
                        column: x => x.BatchID,
                        principalTable: "ProductionBatches",
                        principalColumn: "BatchID");
                    table.ForeignKey(
                        name: "FK__BatchProc__Equip__7E37BEF6",
                        column: x => x.EquipmentID,
                        principalTable: "Equipments",
                        principalColumn: "EquipmentID");
                    table.ForeignKey(
                        name: "FK__BatchProc__Routi__7D439ABD",
                        column: x => x.RoutingID,
                        principalTable: "RecipeRouting",
                        principalColumn: "RoutingID");
                });

            migrationBuilder.CreateTable(
                name: "StepParameters",
                columns: table => new
                {
                    ParameterId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RoutingId = table.Column<int>(type: "int", nullable: true),
                    ParameterName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Unit = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    MinValue = table.Column<decimal>(type: "decimal(18,4)", nullable: true),
                    MaxValue = table.Column<decimal>(type: "decimal(18,4)", nullable: true),
                    IsCritical = table.Column<bool>(type: "bit", nullable: true, defaultValue: true),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StepParameters", x => x.ParameterId);
                    table.ForeignKey(
                        name: "FK_StepParameter_Routing",
                        column: x => x.RoutingId,
                        principalTable: "RecipeRouting",
                        principalColumn: "RoutingID");
                });

            migrationBuilder.CreateTable(
                name: "BatchProcessParameterValues",
                columns: table => new
                {
                    ValueId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    LogId = table.Column<long>(type: "bigint", nullable: true),
                    ParameterId = table.Column<int>(type: "int", nullable: true),
                    ActualValue = table.Column<decimal>(type: "decimal(18,4)", nullable: true),
                    RecordedDate = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BatchProcessParameterValues", x => x.ValueId);
                    table.ForeignKey(
                        name: "FK_ParamValue_Log",
                        column: x => x.LogId,
                        principalTable: "BatchProcessLogs",
                        principalColumn: "LogID");
                    table.ForeignKey(
                        name: "FK_ParamValue_Parameter",
                        column: x => x.ParameterId,
                        principalTable: "StepParameters",
                        principalColumn: "ParameterId");
                });

            migrationBuilder.CreateIndex(
                name: "UQ__AppUsers__536C85E4B8A21C8B",
                table: "AppUsers",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessLogs_BatchID",
                table: "BatchProcessLogs",
                column: "BatchID");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessLogs_EquipmentID",
                table: "BatchProcessLogs",
                column: "EquipmentID");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessLogs_OperatorID",
                table: "BatchProcessLogs",
                column: "OperatorID");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessLogs_RoutingID",
                table: "BatchProcessLogs",
                column: "RoutingID");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessLogs_VerifiedById",
                table: "BatchProcessLogs",
                column: "VerifiedById");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessParameterValues_LogId",
                table: "BatchProcessParameterValues",
                column: "LogId");

            migrationBuilder.CreateIndex(
                name: "IX_BatchProcessParameterValues_ParameterId",
                table: "BatchProcessParameterValues",
                column: "ParameterId");

            migrationBuilder.CreateIndex(
                name: "IX_Equipments_AreaId",
                table: "Equipments",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "UQ__Equipmen__09E4417E23FBF8F4",
                table: "Equipments",
                column: "EquipmentCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_InventoryLots_MaterialId",
                table: "InventoryLots",
                column: "MaterialId");

            migrationBuilder.CreateIndex(
                name: "IX_Materials_BaseUomID",
                table: "Materials",
                column: "BaseUomID");

            migrationBuilder.CreateIndex(
                name: "UQ__Material__170C54BAB161407D",
                table: "Materials",
                column: "MaterialCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MaterialUsage_BatchID",
                table: "MaterialUsage",
                column: "BatchID");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialUsage_DispensedBy",
                table: "MaterialUsage",
                column: "DispensedBy");

            migrationBuilder.CreateIndex(
                name: "IX_MaterialUsage_InventoryLotID",
                table: "MaterialUsage",
                column: "InventoryLotID");

            migrationBuilder.CreateIndex(
                name: "UQ_ProductionAreas_AreaCode",
                table: "ProductionAreas",
                column: "AreaCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProductionBatches_OrderID",
                table: "ProductionBatches",
                column: "OrderID");

            migrationBuilder.CreateIndex(
                name: "UQ__Producti__F869ED6D7BFC6457",
                table: "ProductionBatches",
                column: "BatchNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ProductionOrders_CreatedBy",
                table: "ProductionOrders",
                column: "CreatedBy");

            migrationBuilder.CreateIndex(
                name: "IX_ProductionOrders_RecipeID",
                table: "ProductionOrders",
                column: "RecipeID");

            migrationBuilder.CreateIndex(
                name: "UQ__Producti__999B5229EBD49113",
                table: "ProductionOrders",
                column: "OrderCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RecipeBOM_MaterialID",
                table: "RecipeBOM",
                column: "MaterialID");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeBOM_RecipeID",
                table: "RecipeBOM",
                column: "RecipeID");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeBOM_UomID",
                table: "RecipeBOM",
                column: "UomID");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeRouting_AreaId",
                table: "RecipeRouting",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeRouting_DefaultEquipmentID",
                table: "RecipeRouting",
                column: "DefaultEquipmentID");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeRouting_MaterialId",
                table: "RecipeRouting",
                column: "MaterialId");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeRouting_OrderID",
                table: "RecipeRouting",
                column: "OrderID");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeRouting_RecipeID",
                table: "RecipeRouting",
                column: "RecipeID");

            migrationBuilder.CreateIndex(
                name: "IX_Recipes_ApprovedBy",
                table: "Recipes",
                column: "ApprovedBy");

            migrationBuilder.CreateIndex(
                name: "UQ_Recipe_Version",
                table: "Recipes",
                columns: new[] { "MaterialID", "VersionNumber" },
                unique: true,
                filter: "[MaterialID] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_StepParameters_RoutingId",
                table: "StepParameters",
                column: "RoutingId");

            migrationBuilder.CreateIndex(
                name: "IX_UomConversions_ToUomID",
                table: "UomConversions",
                column: "ToUomID");

            migrationBuilder.CreateIndex(
                name: "UQ_Conversion",
                table: "UomConversions",
                columns: new[] { "FromUomID", "ToUomID" },
                unique: true,
                filter: "[FromUomID] IS NOT NULL AND [ToUomID] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BatchProcessParameterValues");

            migrationBuilder.DropTable(
                name: "MaterialUsage");

            migrationBuilder.DropTable(
                name: "RecipeBOM");

            migrationBuilder.DropTable(
                name: "UomConversions");

            migrationBuilder.DropTable(
                name: "BatchProcessLogs");

            migrationBuilder.DropTable(
                name: "StepParameters");

            migrationBuilder.DropTable(
                name: "InventoryLots");

            migrationBuilder.DropTable(
                name: "ProductionBatches");

            migrationBuilder.DropTable(
                name: "RecipeRouting");

            migrationBuilder.DropTable(
                name: "ProductionOrders");

            migrationBuilder.DropTable(
                name: "Equipments");

            migrationBuilder.DropTable(
                name: "Recipes");

            migrationBuilder.DropTable(
                name: "ProductionAreas");

            migrationBuilder.DropTable(
                name: "AppUsers");

            migrationBuilder.DropTable(
                name: "Materials");

            migrationBuilder.DropTable(
                name: "UnitOfMeasure");
        }
    }
}
