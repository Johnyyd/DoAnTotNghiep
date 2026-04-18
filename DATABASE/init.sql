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

-- =====================================================
-- 1. Master Data (Unit of Measure, Materials, Equipment, Users)
-- =====================================================
PRINT '-- Section 1: Master Data --'

:r ./MasterData.sql

-- =====================================================
-- 2. Recipe and BOM Management
-- =====================================================
PRINT '-- Section 2: Recipes and BOM --'

:r ./ProcessDefinition.sql

-- =====================================================
-- 3. Production Orders and Batches
-- =====================================================
PRINT '-- Section 3: Production Orders & Batches --'

:r ./ProductionExecution.sql
:r ./AdditionalManufacturingProcesses.sql

-- =====================================================
-- 4. Inventory and Traceability
-- =====================================================
PRINT '-- Section 4: Inventory & Traceability --'

:r ./InventoryTraceability.sql

-- =====================================================
-- 5. Quality Control (QC)
-- =====================================================
PRINT '-- Section 5: Quality Control --'

:r ./MaterialQC.sql

-- =====================================================
-- 6. Audit Trail and System Logs
-- =====================================================
PRINT '-- Section 6: Audit Trail --'

:r ./SystemAudit.sql
:r ./AuditTrail.sql

-- =====================================================
-- 7. Advanced Logic (Triggers, Stored Procedures, Constraints)
-- =====================================================
PRINT '-- Section 7: Advanced Logic & Constraints --'

:r ./AdvancedLogic.sql
:r ./Immutability.sql
:r ./Constraints.sql

-- =====================================================
-- 8. Unit Conversions
-- =====================================================
PRINT '-- Section 8: Unit Conversions --'

:r ./UomConversion.sql

-- =====================================================
-- 9. User Management
-- =====================================================
PRINT '-- Section 9: User Management --'

:r ./UserManagement.sql

PRINT 'GMP Database Initialization Completed Successfully!';
