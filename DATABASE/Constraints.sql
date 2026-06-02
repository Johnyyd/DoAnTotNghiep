/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   RÀNG BUỘC NGHIỆP VỤ & TRỰC QUAN HÓA DỮ LIỆU (v1.0)
   Mục đích: Thực thi các quy tắc GMP cứng tại mức CSDL.
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO



-- 2. TRIGGER: CHẶN HOÀN TOÀN MẺ SẤY VƯỢT QUÁ 50KG
-- Kiểm tra giá trị thông số "Khối lượng trước sấy" trong bảng BatchProcessParameterValues.
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Validate_Drying_Limit')
    DROP TRIGGER trg_Validate_Drying_Limit;
GO

CREATE TRIGGER trg_Validate_Drying_Limit
ON BatchProcessParameterValue
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN StepParameters p ON i.ParameterId = p.ParameterId
        WHERE p.ParameterName = N'Khối lượng trước sấy' 
        AND i.ActualValue > 50.0
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Khối lượng mẻ sấy vượt quá giới hạn thiết bị (Tối đa 50kg). Vui lòng phân mẻ sấy nhỏ hơn!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 3. TRIGGER: BẢO TOÀN DỮ LIỆU NHẬT KÝ (IMMUTABILITY)
-- Chặn việc sửa hoặc xóa nhật ký công đoạn khi Mẻ (Batch) đã ở trạng thái 'Completed'.
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Lock_Finalized_Logs')
    DROP TRIGGER trg_Lock_Finalized_Logs;
GO

CREATE TRIGGER trg_Lock_Finalized_Logs
ON BatchProcessLogs
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN ProductionBatches b ON d.BatchId = b.BatchId
        WHERE b.Status = 'Completed'
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Không thể sửa đổi hoặc xóa nhật ký của Mẻ sản xuất đã Hoàn thành (Completed).', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 4. TRIGGER: TỰ ĐỘNG CẬP NHẬT TỒN KHO KHI CẤP PHÁT
-- Khi ghi nhận MaterialUsage, tự động trừ số lượng trong InventoryLots.
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Update_Inventory_On_Usage')
    DROP TRIGGER trg_Update_Inventory_On_Usage;
GO

CREATE TRIGGER trg_Update_Inventory_On_Usage
ON MaterialUsage
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE l
    SET l.QuantityCurrent = l.QuantityCurrent - i.ActualAmount
    FROM InventoryLots l
    JOIN inserted i ON l.LotID = i.InventoryLotID;
END;
GO

-- 5. TRIGGER: BẢO TOÀN NHẬT KÝ HỆ THỐNG (IMMUTABILITY OF AUDIT LOGS)
CREATE OR ALTER TRIGGER trg_Prevent_Delete_SystemAuditLog
ON SystemAuditLog
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    RAISERROR(N'LỖI GMP: Tuyệt đối không được sửa hoặc xóa nhật ký hệ thống (SystemAuditLog).', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

-- 6. TRIGGER: CHẶN CẤP PHÁT NGUYÊN LIỆU HẾT HẠN
CREATE OR ALTER TRIGGER trg_Prevent_Expired_Material_Usage
ON MaterialUsage
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN InventoryLots l ON i.InventoryLotId = l.LotId
        WHERE l.ExpiryDate < GETDATE()
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Nguyên liệu này đã hết hạn sử dụng (Expired), không được phép cấp phát cho mẻ sản xuất.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 7. TRIGGER: CHẶN SỬA ĐỔI CÔNG THỨC ĐÃ PHÊ DUYỆT
CREATE OR ALTER TRIGGER trg_Prevent_Recipe_Modifications
ON Recipes
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM deleted d
        WHERE d.Status = 'Approved'
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Không được phép sửa đổi hoặc xóa công thức (Recipe) đã được Phê duyệt (Approved). Vui lòng tạo phiên bản mới.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 8. TRIGGER: BẢO TOÀN NGƯỜI DÙNG (CHUYỂN TRẠNG THÁI THAY VÌ XÓA)
CREATE OR ALTER TRIGGER trg_Enforce_User_Deactivation
ON AppUsers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AppUsers
    SET IsActive = 0
    WHERE UserId IN (SELECT UserId FROM deleted);
    
    PRINT 'GMP INFO: Nguoi dung da duoc vo hieu hoa (IsActive = 0) thay vi xoa de dam bao toan ven nhat ky.';
END;
GO

-- 9. TRIGGER: CHẶN TỒN KHO ÂM
CREATE OR ALTER TRIGGER trg_Prevent_Negative_Inventory
ON InventoryLots
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE i.QuantityCurrent < 0
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Số lượng tồn kho không được phép nhỏ hơn 0. Giao dịch bị từ chối.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 10. TRIGGER: CHẶN QUAY LÙI TRẠNG THÁI MẺ SẢN XUẤT ĐÃ HOÀN THÀNH
CREATE OR ALTER TRIGGER trg_Validate_Batch_Status_Flow
ON ProductionBatches
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.BatchId = d.BatchId
        WHERE d.Status = 'Completed' AND i.Status != 'Completed'
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Mẻ sản xuất đã Hoàn thành (Completed) không thể quay ngược trạng thái.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT 'Da khoi tao cac rang buoc GMP thanh cong.';
GO
