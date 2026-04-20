/* =========================================================================
   HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
   RÀNG BUỘC NGHIỆP VỤ & TRỰC QUAN HÓA DỮ LIỆU (v1.0)
   Mục đích: Thực thi các quy tắc GMP cứng tại mức CSDL.
   ========================================================================= */

USE [PharmaceuticalProcessingManagementSystem];
GO

-- 1. TRIGGER: KIỂM TRA TRẠNG THÁI QC NGUYÊN LIỆU (QC RELEASE ONLY)
-- Chặn việc sử dụng bất kỳ lô nguyên vật liệu nào chưa được "Released".
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Check_Material_QC')
    DROP TRIGGER trg_Check_Material_QC;
GO

CREATE TRIGGER trg_Check_Material_QC
ON MaterialUsage
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN InventoryLots l ON i.InventoryLotID = l.LotID
        WHERE l.QCStatus <> 'Released'
    )
    BEGIN
        RAISERROR(N'LỖI GMP: Lô nguyên vật liệu chưa được QC duyệt (Released). Không thể cấp phát!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 2. TRIGGER: CHẶN HOÀN TOÀN MẺ SẤY VƯỢT QUÁ 50KG
-- Kiểm tra giá trị thông số "Khối lượng trước sấy" trong bảng BatchProcessParameterValues.
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_Validate_Drying_Limit')
    DROP TRIGGER trg_Validate_Drying_Limit;
GO

CREATE TRIGGER trg_Validate_Drying_Limit
ON BatchProcessParameterValues
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

PRINT 'Da khoi tao cac rang buoc GMP thanh cong.';
GO
