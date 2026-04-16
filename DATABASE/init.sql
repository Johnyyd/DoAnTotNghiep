-- ============================================================================
-- 💊 HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
-- KỊCH BẢN KHỞI TẠO CƠ SỞ DỮ LIỆU (ENTRY POINT)
-- 
-- File này là "Điểm bắt đầu" để thiết lập toàn bộ cấu trúc DB. 
-- Nó sẽ tự động tạo Database PharmaceuticalProcessingManagementSystem
-- sau đó gọi lần lượt các file thành phần (Module) theo đúng thứ tự logic.
-- ============================================================================

USE master;
GO

-- 1. TẠO DATABASE MỚI (Nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PharmaceuticalProcessingManagementSystem')
BEGIN
    CREATE DATABASE [PharmaceuticalProcessingManagementSystem];
END
GO

USE [PharmaceuticalProcessingManagementSystem];
GO

PRINT 'Starting GMP Database Initialization...';

PRINT '-- Section 1: Schema --'

:r ./Schema.sql

PRINT '-- Section 2: Audit Trail --'

:r ./SystemAudit.sql

PRINT '-- Section 3: Additional Manufacturing Processes --'

:r ./AdditionalManufacturingProcesses.sql

PRINT '-- Section 4: Full Seed Data --'

:r ./full_seed.sql

PRINT 'Full Seed Data Completed Successfully!';