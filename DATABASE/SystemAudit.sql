-- ============================================================================
-- MODULE: NHẬT KÝ HỆ THỐNG (SYSTEM AUDIT LOGS)
-- 
-- Chứa bảng tổng hợp mọi hành động thay đổi dữ liệu của người dùng.
-- Đáp ứng yêu cầu truy vết ngược (Traceability) của GMP.
-- ============================================================================

-- Trigger mẫu để tự động ghi log thao tác CRUD
CREATE OR ALTER TRIGGER trg_Audit_Materials ON Materials
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
    SELECT
        'Materials',
        CAST(COALESCE(i.MaterialId, d.MaterialId) AS NVARCHAR(100)),
        CASE
            WHEN i.MaterialId IS NOT NULL AND d.MaterialId IS NULL THEN 'Create'
            WHEN i.MaterialId IS NOT NULL AND d.MaterialId IS NOT NULL THEN 'Update'
            ELSE 'Delete'
        END,
        CASE WHEN d.MaterialId IS NULL THEN NULL ELSE CONCAT('Code=', d.MaterialCode, ';Name=', d.MaterialName) END,
        CASE WHEN i.MaterialId IS NULL THEN NULL ELSE CONCAT('Code=', i.MaterialCode, ';Name=', i.MaterialName) END,
        GETDATE()
    FROM inserted i
    FULL JOIN deleted d ON i.MaterialId = d.MaterialId;
END;
GO

CREATE OR ALTER TRIGGER trg_Audit_ProductionOrders ON ProductionOrders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SystemAuditLog(TableName, RecordId, Action, OldValue, NewValue, ChangedDate)
    SELECT
        'ProductionOrders',
        CAST(COALESCE(i.OrderId, d.OrderId) AS NVARCHAR(100)),
        CASE
            WHEN i.OrderId IS NOT NULL AND d.OrderId IS NULL THEN 'Create'
            WHEN i.OrderId IS NOT NULL AND d.OrderId IS NOT NULL THEN 'Update'
            ELSE 'Delete'
        END,
        CASE WHEN d.OrderId IS NULL THEN NULL ELSE CONCAT('Code=', d.OrderCode, ';Status=', d.Status) END,
        CASE WHEN i.OrderId IS NULL THEN NULL ELSE CONCAT('Code=', i.OrderCode, ';Status=', i.Status) END,
        GETDATE()
    FROM inserted i
    FULL JOIN deleted d ON i.OrderId = d.OrderId;
END;
GO
