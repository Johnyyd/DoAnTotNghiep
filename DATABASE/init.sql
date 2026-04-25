-- ============================================================================
-- HỆ THỐNG QUẢN LÝ SẢN XUẤT DƯỢC PHẨM (GMP-WHO)
-- KỊCH BẢN KHỞI TẠO CƠ SỞ DỮ LIỆU (CHỐNG LỖI ĐƯỜNG DẪN)
-- ============================================================================

-- BƯỚC 1: SỬA ĐƯỜNG DẪN DƯỚI ĐÂY KHỚP VỚI MÁY CỦA BẠN (Cần có dấu \ ở cuối)
:setvar BaseDir "d:\codes\Antigravity\DoAnTotNghiep\DATABASE\"

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PharmaceuticalProcessingManagementSystem')
BEGIN
    CREATE DATABASE [PharmaceuticalProcessingManagementSystem];
END
GO

USE [PharmaceuticalProcessingManagementSystem];
GO

PRINT 'Starting GMP Database Initialization...';

-- BƯỚC 2: GỌI CÁC FILE DỰA TRÊN BIẾN BaseDir
PRINT '-- Section 1: Schema --'
:r $(BaseDir)Schema.sql

PRINT '-- Section 2: Full Seed Data --'
:r $(BaseDir)full_seed.sql

PRINT 'GMP Database Initialization & Seeding Completed Successfully!';
