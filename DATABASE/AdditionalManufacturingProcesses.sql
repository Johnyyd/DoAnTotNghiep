USE PharmaceuticalProcessingManagementSystem;
GO
-- ============================================================================
-- 0. Cập nhật cấu trúc bảng (Schema Migration) nếu bị thiếu cột
-- ============================================================================
IF COL_LENGTH('Materials', 'TechnicalSpecification') IS NULL ALTER TABLE Materials ADD TechnicalSpecification NVARCHAR(500);
IF COL_LENGTH('Materials', 'CreatedAt') IS NULL ALTER TABLE Materials ADD CreatedAt DATETIME2 DEFAULT GETDATE();
IF COL_LENGTH('Materials', 'UpdatedAt') IS NULL ALTER TABLE Materials ADD UpdatedAt DATETIME2;

IF COL_LENGTH('Recipes', 'CreatedAt') IS NULL ALTER TABLE Recipes ADD CreatedAt DATETIME2 DEFAULT GETDATE();
IF COL_LENGTH('Recipes', 'EffectiveDate') IS NULL ALTER TABLE Recipes ADD EffectiveDate DATETIME2;
IF COL_LENGTH('Recipes', 'Note') IS NULL ALTER TABLE Recipes ADD Note NVARCHAR(500);

IF COL_LENGTH('RecipeRouting', 'NumberOfRouting') IS NULL ALTER TABLE RecipeRouting ADD NumberOfRouting INT DEFAULT 1;

IF COL_LENGTH('ProductionBatches', 'EndTime') IS NULL ALTER TABLE ProductionBatches ADD EndTime DATETIME2;
IF COL_LENGTH('ProductionBatches', 'CreatedAt') IS NULL ALTER TABLE ProductionBatches ADD CreatedAt DATETIME2 DEFAULT GETDATE();

IF COL_LENGTH('BatchProcessLogs', 'NumberOfRouting') IS NULL ALTER TABLE BatchProcessLogs ADD NumberOfRouting INT DEFAULT 1;
GO

-- ============================================================================
-- Bổ sung quy trình sản xuất mới và dữ liệu mẫu cho NumberOfRouting
-- - Thuốc ống Dipyridamole 10mg/2ml
-- - Viên nén Paracetamol 500mg
-- - Ví dụ công đoạn sấy có thể lặp lại nhiều lần
-- ============================================================================

SET NOCOUNT ON;

-- --------------------------------------------------------------------------
-- 1. Materials bổ sung
-- --------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialCode = 'MAT-WATER')
BEGIN
    INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification)
    VALUES ('MAT-WATER', N'Nước cất pha tiêm', 'RawMaterial', 3, 1, N'Nước cất vô trùng');
END;

IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialCode = 'MAT-AMP')
BEGIN
    INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification)
    VALUES ('MAT-AMP', N'Ống thủy tinh 2ml', 'Packaging', 4, 1, N'Bao bì sơ cấp cho thuốc ống');
END;

IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialCode = 'FG-DIPY-AMP')
BEGIN
    INSERT INTO Materials (MaterialCode, MaterialName, Type, BaseUomId, IsActive, TechnicalSpecification)
    VALUES ('FG-DIPY-AMP', N'Thuốc ống Dipyridamole 10mg/2ml', 'FinishedGood', 4, 1, N'Thành phẩm thuốc ống');
END;

-- --------------------------------------------------------------------------
-- 2. Recipe: Thuốc ống Dipyridamole 10mg/2ml
-- --------------------------------------------------------------------------
DECLARE @AmpouleMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'FG-DIPY-AMP');
DECLARE @WaterMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-WATER');
DECLARE @AmpoulePackMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-AMP');
DECLARE @ApprovedByUserId INT = (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'QA_QC' ORDER BY UserId);
DECLARE @RecipeAmpouleId INT;

SELECT @RecipeAmpouleId = RecipeId
FROM Recipes
WHERE MaterialId = @AmpouleMaterialId AND VersionNumber = 1;

IF @RecipeAmpouleId IS NULL AND @AmpouleMaterialId IS NOT NULL
BEGIN
    INSERT INTO Recipes (MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, EffectiveDate, Note)
    VALUES (@AmpouleMaterialId, 1, 10000.00, 'Approved', @ApprovedByUserId, GETDATE(), GETDATE(), GETDATE(),
        N'Quy trình chuẩn cho thuốc ống Dipyridamole 10mg/2ml.');

    SET @RecipeAmpouleId = SCOPE_IDENTITY();
END;

IF @RecipeAmpouleId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM RecipeBom WHERE RecipeId = @RecipeAmpouleId AND MaterialId = @WaterMaterialId)
    BEGIN
        INSERT INTO RecipeBom (RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note)
        VALUES (@RecipeAmpouleId, @WaterMaterialId, 5000.00, 3, 0.20, N'Nước cất pha tiêm');
    END;

    IF NOT EXISTS (SELECT 1 FROM RecipeBom WHERE RecipeId = @RecipeAmpouleId AND MaterialId = @AmpoulePackMaterialId)
    BEGIN
        INSERT INTO RecipeBom (RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note)
        VALUES (@RecipeAmpouleId, @AmpoulePackMaterialId, 10000.00, 4, 0.10, N'Ống thủy tinh 2ml');
    END;

    IF NOT EXISTS (SELECT 1 FROM RecipeRouting WHERE RecipeId = @RecipeAmpouleId AND StepNumber = 1)
    BEGIN
        INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description, NumberOfRouting)
        VALUES
        (@RecipeAmpouleId, 1, N'Pha chế dung dịch', NULL, 60, N'Pha hoạt chất vào nước cất vô trùng.', 1),
        (@RecipeAmpouleId, 2, N'Lọc vô trùng', NULL, 45, N'Lọc qua màng 0.22 micron.', 1),
        (@RecipeAmpouleId, 3, N'Đóng ống - Hàn ống', NULL, 120, N'Chiết rót 2ml/ống và hàn kín.', 1),
        (@RecipeAmpouleId, 4, N'Tiệt trùng', NULL, 90, N'Tiệt trùng bằng autoclave ở 121°C.', 1),
        (@RecipeAmpouleId, 5, N'Soi kiểm tra', NULL, 180, N'Kiểm tra độ trong và tiểu phân lạ.', 1);
    END;

    DECLARE @AmpouleMixRoutingId INT = (
        SELECT TOP 1 RoutingId FROM RecipeRouting
        WHERE RecipeId = @RecipeAmpouleId AND StepNumber = 1
    );
    DECLARE @AmpouleSterileRoutingId INT = (
        SELECT TOP 1 RoutingId FROM RecipeRouting
        WHERE RecipeId = @RecipeAmpouleId AND StepNumber = 4
    );

    IF @AmpouleMixRoutingId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM StepParameters WHERE RoutingId = @AmpouleMixRoutingId AND ParameterName = N'Tốc độ cánh khuấy')
    BEGIN
        INSERT INTO StepParameters (RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical, Note)
        VALUES
        (@AmpouleMixRoutingId, N'Tốc độ cánh khuấy', N'v/p', 50, 60, 1, N'Kiểm soát đồng nhất dung dịch'),
        (@AmpouleMixRoutingId, N'Thời gian pha', N'phút', 30, 45, 1, N'Thời gian hòa tan chuẩn');
    END;

    IF @AmpouleSterileRoutingId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM StepParameters WHERE RoutingId = @AmpouleSterileRoutingId AND ParameterName = N'Nhiệt độ tiệt trùng')
    BEGIN
        INSERT INTO StepParameters (RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical, Note)
        VALUES
        (@AmpouleSterileRoutingId, N'Nhiệt độ tiệt trùng', N'°C', 121, 122, 1, N'Giữ nhiệt độ vô trùng chuẩn');
    END;
END;

-- --------------------------------------------------------------------------
-- 3. Recipe: Viên nén Paracetamol 500mg có bước sấy lặp lại
-- --------------------------------------------------------------------------
DECLARE @TabletMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'FG-PARA-TAB');
DECLARE @ParacetamolMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-PARA');
DECLARE @StarchMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-TD8');
DECLARE @LactoseMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-LAC');
DECLARE @MagStearateMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-TD5');
DECLARE @PvpMaterialId INT = (SELECT MaterialId FROM Materials WHERE MaterialCode = 'MAT-PVP');
DECLARE @TabletRecipeId INT;

SELECT @TabletRecipeId = RecipeId
FROM Recipes
WHERE MaterialId = @TabletMaterialId AND VersionNumber = 3;

IF @TabletRecipeId IS NULL AND @TabletMaterialId IS NOT NULL
BEGIN
    INSERT INTO Recipes (MaterialId, VersionNumber, BatchSize, Status, ApprovedBy, ApprovedDate, CreatedAt, EffectiveDate, Note)
    VALUES (@TabletMaterialId, 3, 200000.00, 'Approved', @ApprovedByUserId, GETDATE(), GETDATE(), GETDATE(),
        N'Quy trình viên nén Paracetamol với công đoạn sấy hạt có thể lặp lại.');

    SET @TabletRecipeId = SCOPE_IDENTITY();
END;

IF @TabletRecipeId IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM RecipeBom WHERE RecipeId = @TabletRecipeId AND MaterialId = @ParacetamolMaterialId)
    BEGIN
        INSERT INTO RecipeBom (RecipeId, MaterialId, Quantity, UomId, WastePercentage, Note)
        VALUES
        (@TabletRecipeId, @ParacetamolMaterialId, 100000.00, 2, 0.30, N'Paracetamol hoạt chất'),
        (@TabletRecipeId, @StarchMaterialId, 60000.00, 2, 0.80, N'Tinh bột ngô'),
        (@TabletRecipeId, @LactoseMaterialId, 30000.00, 2, 0.50, N'Lactose'),
        (@TabletRecipeId, @MagStearateMaterialId, 2500.00, 2, 0.10, N'Magnesi stearat'),
        (@TabletRecipeId, @PvpMaterialId, 4000.00, 2, 0.20, N'PVP K30');
    END;

    IF NOT EXISTS (SELECT 1 FROM RecipeRouting WHERE RecipeId = @TabletRecipeId AND StepNumber = 1)
    BEGIN
        INSERT INTO RecipeRouting (RecipeId, StepNumber, StepName, DefaultEquipmentId, EstimatedTimeMinutes, Description, NumberOfRouting)
        VALUES
        (@TabletRecipeId, 1, N'Cân nguyên liệu', 1, 90, N'Cân Paracetamol và tá dược theo BOM.', 1),
        (@TabletRecipeId, 2, N'Trộn khô', 3, 15, N'Trộn đều bột hoạt chất và tá dược.', 1),
        (@TabletRecipeId, 3, N'Tạo hạt ướt', NULL, 60, N'Thêm dung dịch PVP K30 để tạo hạt.', 1),
        (@TabletRecipeId, 4, N'Sấy hạt tầng sôi', 2, 120, N'Sấy đến khi độ ẩm hạt sau sấy đạt chuẩn.', 2),
        (@TabletRecipeId, 5, N'Sửa hạt', NULL, 60, N'Rây sửa hạt sau sấy.', 1),
        (@TabletRecipeId, 6, N'Dập viên', 4, 180, N'Dập viên nén Paracetamol 500mg.', 1);
    END;

    DECLARE @TabletDryingRoutingId INT = (
        SELECT TOP 1 RoutingId FROM RecipeRouting
        WHERE RecipeId = @TabletRecipeId AND StepNumber = 4
    );

    IF @TabletDryingRoutingId IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM StepParameters WHERE RoutingId = @TabletDryingRoutingId AND ParameterName = N'Độ ẩm hạt sau sấy')
    BEGIN
        INSERT INTO StepParameters (RoutingId, ParameterName, Unit, MinValue, MaxValue, IsCritical, Note)
        VALUES
        (@TabletDryingRoutingId, N'Nhiệt độ sấy tầng sôi', N'°C', 60, 70, 1, N'Nhiệt độ sấy chuẩn'),
        (@TabletDryingRoutingId, N'Độ ẩm hạt sau sấy', N'%', NULL, 5.0, 1, N'Nếu vượt 5% phải quay lại sấy thêm');
    END;

    DECLARE @TabletOrderId INT;
    SELECT @TabletOrderId = OrderId FROM ProductionOrders WHERE OrderCode = 'PO-LOOP-001';

    IF @TabletOrderId IS NULL
    BEGIN
        INSERT INTO ProductionOrders (OrderCode, RecipeId, PlannedQuantity, ActualQuantity, StartDate, EndDate, Status, CreatedBy, CreatedAt, Note)
        VALUES ('PO-LOOP-001', @TabletRecipeId, 200000.00, NULL, DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, 2, GETDATE()),
            'In-Process', COALESCE((SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'ProductionManager' ORDER BY UserId), @ApprovedByUserId), GETDATE(),
            N'Đơn hàng mẫu cho công đoạn sấy có thể lặp.');

        SET @TabletOrderId = SCOPE_IDENTITY();
    END;

    DECLARE @TabletBatchId INT;
    SELECT @TabletBatchId = BatchId FROM ProductionBatches WHERE BatchNumber = 'B-LOOP-001';

    IF @TabletBatchId IS NULL
    BEGIN
        INSERT INTO ProductionBatches (OrderId, BatchNumber, Status, ManufactureDate, EndTime, ExpiryDate, CurrentStep, CreatedAt)
        VALUES (@TabletOrderId, 'B-LOOP-001', 'InProcess', DATEADD(HOUR, -10, GETDATE()), NULL, DATEADD(YEAR, 2, GETDATE()), 4, GETDATE());

        SET @TabletBatchId = SCOPE_IDENTITY();
    END;

    DECLARE @RoutingWeighId INT = (SELECT TOP 1 RoutingId FROM RecipeRouting WHERE RecipeId = @TabletRecipeId AND StepNumber = 1);
    DECLARE @RoutingMixId INT = (SELECT TOP 1 RoutingId FROM RecipeRouting WHERE RecipeId = @TabletRecipeId AND StepNumber = 2);
    DECLARE @RoutingWetId INT = (SELECT TOP 1 RoutingId FROM RecipeRouting WHERE RecipeId = @TabletRecipeId AND StepNumber = 3);

    IF @TabletBatchId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM BatchProcessLogs WHERE BatchId = @TabletBatchId AND RoutingId = @RoutingWeighId AND NumberOfRouting = 1)
        BEGIN
            INSERT INTO BatchProcessLogs (BatchId, RoutingId, EquipmentId, OperatorId, StartTime, EndTime, ResultStatus, ParametersData, NumberOfRouting)
            VALUES
            (@TabletBatchId, @RoutingWeighId, 1, (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'Operator' ORDER BY UserId),
                DATEADD(HOUR, -10, GETDATE()), DATEADD(HOUR, -9, GETDATE()), 'Passed',
                N'{"soLo":"B-LOOP-001","congDoan":"Can nguyen lieu","ketQua":"Dat"}', 1),
            (@TabletBatchId, @RoutingMixId, 3, (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'Operator' ORDER BY UserId),
                DATEADD(HOUR, -9, GETDATE()), DATEADD(HOUR, -8, GETDATE()), 'Passed',
                N'{"soLo":"B-LOOP-001","congDoan":"Tron kho","tocDoTron":15,"ketQua":"Dat"}', 1),
            (@TabletBatchId, @RoutingWetId, 3, (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'Operator' ORDER BY UserId),
                DATEADD(HOUR, -8, GETDATE()), DATEADD(HOUR, -7, GETDATE()), 'Passed',
                N'{"soLo":"B-LOOP-001","congDoan":"Tao hat uot","ketQua":"Dat"}', 1),
            (@TabletBatchId, @TabletDryingRoutingId, 2, (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'Operator' ORDER BY UserId),
                DATEADD(HOUR, -7, GETDATE()), DATEADD(HOUR, -5, GETDATE()), 'Failed',
                N'{"soLo":"B-LOOP-001","congDoan":"Say hat tang soi","nhietDoSayTangSoi":68.0,"doAmHatSauSay":6.2,"ketQua":"KhongDat"}', 1),
            (@TabletBatchId, @TabletDryingRoutingId, 2, (SELECT TOP 1 UserId FROM AppUsers WHERE Role = 'Operator' ORDER BY UserId),
                DATEADD(HOUR, -4, GETDATE()), NULL, 'Running',
                N'{"soLo":"B-LOOP-001","congDoan":"Say hat tang soi","nhietDoSayTangSoi":66.0,"doAmHatSauSay":5.4,"ketQua":"DangThucHien"}', 2);
        END;
    END;
END;
