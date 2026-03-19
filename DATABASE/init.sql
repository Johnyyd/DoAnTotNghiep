-- =====================================================
-- GMP-WHO Pharmaceutical Processing Management System
-- Database Initialization Script (Kịch bản khởi tạo Cơ Sở Dữ Liệu)
-- File này đóng vai trò như Entry Point chạy thứ tự các kịch bản tạo cấu trúc SQL (Schema, Tables),
-- từ Master Data cơ sở cho đến Logic chạy phức tạp (Trigger, Procedures) dùng trên SQL Server Container
-- =====================================================

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
-- 7. Advanced Logic (Triggers, Stored Procedures)
-- =====================================================
PRINT '-- Section 7: Advanced Logic --'

:r ./AdvancedLogic.sql
:r ./Immutability.sql

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
