/* =========================================================================
   Hệ thống Quản lý Sản xuất Dược phẩm (GMP-WHO)
   Script: TRUY VẤN TOÀN BỘ DỮ LIỆU (DATABASE EXPLORER)
   Mục đích: Kiểm tra nhanh trạng thái dữ liệu trong tất cả các bảng.
========================================================================= */

-- 1. NHÓM DANH MỤC MASTER DATA (Dữ liệu gốc)
PRINT '--- 1. MASTER DATA ---';
SELECT * FROM AppUsers; -- Người dùng
SELECT * FROM UnitOfMeasure; -- Đơn vị tính
SELECT * FROM UomConversions; -- Quy đổi đơn vị
SELECT * FROM Equipments; -- Thiết bị, máy móc
SELECT * FROM Materials; -- Nguyên liệu, thành phẩm

-- 2. NHÓM CÔNG THỨC & QUY TRÌNH (Recipe & Routing)
PRINT '--- 2. RECIPES & ROUTINGS ---';
SELECT * FROM Recipes; -- Công thức gốc
SELECT * FROM RecipeBom; -- Định mức vật tư
SELECT * FROM RecipeRouting; -- Các bước quy trình
SELECT * FROM StepParameters; -- Thông số kỹ thuật chuẩn

-- 3. NHÓM LỆNH SẢN XUẤT & MẺ (Orders & Batches)
PRINT '--- 3. PRODUCTION ORDERS & BATCHES ---';
SELECT * FROM ProductionOrders; -- Lệnh sản xuất tổng
SELECT * FROM ProductionBatches; -- Các mẻ (lô) chi tiết

-- 4. NHÓM NHẬT KÝ SẢN XUẤT (eBMR - Hồ sơ lô điện tử)
PRINT '--- 4. PRODUCTION LOGS (eBMR) ---';
SELECT * FROM BatchProcessLogs; -- Nhật ký công đoạn
SELECT * FROM BatchProcessParameterValue; -- Giá trị thông số thực tế

-- 5. NHÓM KHO & CHẤT LƯỢNG (Inventory & QC)
PRINT '--- 5. INVENTORY & QUALITY ---';
SELECT * FROM InventoryLots; -- Quản lý tồn kho theo lô
SELECT * FROM MaterialUsage; -- Lịch sử sử dụng nguyên liệu
SELECT * FROM QualityTests; -- Kết quả kiểm nghiệm (Lab)

-- 6. HỆ THỐNG (System)
PRINT '--- 6. SYSTEM AUDIT ---';
SELECT * FROM SystemAuditLog; -- Dấu vết kiểm toán (Audit Trail)


/* =========================================================================
   TRUY VẤN TỔNG HỢP (MASTER VIEWS - Dành cho báo cáo nhanh)
========================================================================= */

-- A. Xem chi tiết Lệnh sản xuất và Công thức tương ứng
PRINT '--- VIEW A: PRODUCTION ORDERS WITH RECIPES ---';
SELECT 
    PO.OrderCode, 
    M.MaterialName AS Product, 
    R.VersionNumber, 
    PO.PlannedQuantity, 
    PO.Status, 
    PO.StartDate
FROM ProductionOrders PO
JOIN Recipes R ON PO.RecipeId = R.RecipeId
JOIN Materials M ON R.MaterialId = M.MaterialId;

-- B. Xem chi tiết Quy trình và Thông số chuẩn của 1 Công thức
PRINT '--- VIEW B: ROUTING & PARAMETERS ---';
SELECT 
    R.RecipeId,
    RR.StepNumber, 
    RR.StepName, 
    SP.ParameterName, 
    SP.MinValue, 
    SP.MaxValue, 
    SP.Unit
FROM RecipeRouting RR
LEFT JOIN StepParameters SP ON RR.RoutingId = SP.RoutingId
JOIN Recipes R ON RR.RecipeId = R.RecipeId
ORDER BY R.RecipeId, RR.StepNumber;

-- C. Truy vết Nguyên liệu dùng cho từng Mẻ (Inventory Traceability)
PRINT '--- VIEW C: BATCH MATERIAL TRACEABILITY ---';
SELECT 
    PB.BatchNumber, 
    M.MaterialName, 
    IL.LotNumber AS SourceLot, 
    MU.QuantityUsed, 
    MU.UsedDate
FROM MaterialUsage MU
JOIN ProductionBatches PB ON MU.BatchId = PB.BatchId
JOIN InventoryLots IL ON MU.InventoryLotId = IL.LotId
JOIN Materials M ON IL.MaterialId = M.MaterialId;

-- D. Cảnh báo Tồn kho: Sắp hết hạn (trong 30 ngày) hoặc đã hết hạn
PRINT '--- VIEW D: EXPIRY DATE ALERTS (Next 30 Days) ---';
SELECT 
    M.MaterialCode, 
    M.MaterialName, 
    IL.LotNumber, 
    IL.QuantityCurrent, 
    IL.ExpiryDate,
    DATEDIFF(day, GETDATE(), IL.ExpiryDate) AS DaysRemaining
FROM InventoryLots IL
JOIN Materials M ON IL.MaterialId = M.MaterialId
WHERE IL.ExpiryDate <= DATEADD(day, 30, GETDATE())
ORDER BY IL.ExpiryDate ASC;

-- E. Danh sách các bước có sai lệch (Deviations) cần QA thẩm duyệt
PRINT '--- VIEW E: PRODUCTION DEVIATIONS ---';
SELECT 
    PB.BatchNumber, 
    RR.StepName, 
    BPL.StartTime, 
    BPL.Notes AS DeviationDetail,
    U.FullName AS Operator
FROM BatchProcessLogs BPL
JOIN ProductionBatches PB ON BPL.BatchId = PB.BatchId
JOIN RecipeRouting RR ON BPL.RoutingId = RR.RoutingId
JOIN AppUsers U ON BPL.OperatorId = U.UserId
WHERE BPL.IsDeviation = 1;

-- F. Báo cáo Hiệu suất Lệnh sản xuất (Yield Analysis)
PRINT '--- VIEW F: YIELD ANALYSIS ---';
SELECT 
    OrderCode, 
    PlannedQuantity, 
    ActualQuantity,
    CASE 
        WHEN PlannedQuantity > 0 THEN (ActualQuantity / PlannedQuantity) * 100 
        ELSE 0 
    END AS YieldPercentage
FROM ProductionOrders
WHERE Status = 'Completed';

-- G. Trạng thái Thiết bị và Bảo trì
PRINT '--- VIEW G: EQUIPMENT STATUS & MAINTENANCE ---';
SELECT 
    EquipmentCode, 
    EquipmentName, 
    Status, 
    LastMaintenanceDate,
    DATEDIFF(day, LastMaintenanceDate, GETDATE()) AS DaysSinceMaintenance
FROM Equipments
ORDER BY Status, LastMaintenanceDate;

-- H. Top 20 thay đổi dữ liệu gần nhất (Audit Trail)
PRINT '--- VIEW H: RECENT DATA CHANGES (Top 20) ---';
SELECT TOP 20
    Action, 
    TableName, 
    RecordId, 
    U.FullName AS ChangedBy, 
    ChangedDate
FROM SystemAuditLog AL
JOIN AppUsers U ON AL.ChangedBy = U.UserId
ORDER BY ChangedDate DESC;

-- I. Giám sát các mẻ đang "mắc kẹt" (Stuck Batches)
-- Tìm các bước đang chạy (Running) vượt quá 150% thời gian dự kiến
PRINT '--- VIEW I: STUCK BATCHES ALERT ---';
SELECT 
    PB.BatchNumber, 
    RR.StepName, 
    BPL.StartTime,
    RR.EstimatedTimeMinutes,
    DATEDIFF(minute, BPL.StartTime, GETDATE()) AS ActualMinutesSoFar
FROM BatchProcessLogs BPL
JOIN ProductionBatches PB ON BPL.BatchId = PB.BatchId
JOIN RecipeRouting RR ON BPL.RoutingId = RR.RoutingId
WHERE BPL.ResultStatus = 'Running' 
  AND DATEDIFF(minute, BPL.StartTime, GETDATE()) > (RR.EstimatedTimeMinutes * 1.5);

-- J. Tổng hợp hoạt động người dùng (User Productivity)
PRINT '--- VIEW J: USER ACTIVITY SUMMARY ---';
SELECT 
    U.FullName, 
    U.Role,
    (SELECT COUNT(*) FROM BatchProcessLogs WHERE OperatorId = U.UserId) AS StepsPerformed,
    (SELECT COUNT(*) FROM BatchProcessLogs WHERE VerifiedById = U.UserId) AS StepsVerified,
    (SELECT COUNT(*) FROM ProductionOrders WHERE CreatedBy = U.UserId) AS OrdersCreated
FROM AppUsers U
WHERE U.IsActive = 1
ORDER BY StepsPerformed DESC;
