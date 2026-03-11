USE master;
GO

:setvar path "C:\LUUDULIEU\PharmaceuticalProcessingManagementSystem\PharmaceuticalProcessingManagementSystem\PharmaceuticalProcessingManagementSystem"

-- 1. CLEAN UP
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'PharmaceuticalProcessingManagementSystem')
BEGIN
    ALTER DATABASE [PharmaceuticalProcessingManagementSystem] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [PharmaceuticalProcessingManagementSystem];
END
GO

-- 2. SETUP
CREATE DATABASE [PharmaceuticalProcessingManagementSystem];
GO

USE [PharmaceuticalProcessingManagementSystem];
GO

PRINT '--- BAT DAU KHOI TAO HE THONG (FULL) ---'

-- 3. CORE MODULES

PRINT '--> 1. MasterData.sql...'
GO -- Ng?t lô l?nh in ?n
:r $(path)\MasterData.sql
GO -- Ng?t lô l?nh t?o b?ng

PRINT '--> 1.1. UserManagement.sql (Tao bang User)...'
GO
:r $(path)\UserManagement.sql
GO

PRINT '--> 1.2. UomConversion.sql...'
GO
:r $(path)\UomConversion.sql
GO

PRINT '--> 2. ProcessDefinition.sql...'
GO
:r $(path)\ProcessDefinition.sql
GO

PRINT '--> 3. ProductionExecution.sql...'
GO
:r $(path)\ProductionExecution.sql
GO

PRINT '--> 4. InventoryTraceability.sql...'
GO
:r $(path)\InventoryTraceability.sql
GO

PRINT '--> 5. SystemAudit.sql...'
GO
:r $(path)\SystemAudit.sql
GO

-- 4. LINKING (T?o khóa ngo?i sau cùng)
PRINT '--> 5.1. Tao Foreign Key cho User...'
GO
ALTER TABLE Recipes ADD CONSTRAINT FK_Recipes_User FOREIGN KEY (ApprovedBy) REFERENCES AppUsers(UserID);
ALTER TABLE ProductionOrders ADD CONSTRAINT FK_Orders_User FOREIGN KEY (CreatedBy) REFERENCES AppUsers(UserID);
ALTER TABLE MaterialUsage ADD CONSTRAINT FK_Usage_User FOREIGN KEY (DispensedBy) REFERENCES AppUsers(UserID);
ALTER TABLE SystemAuditLog ADD CONSTRAINT FK_Audit_User FOREIGN KEY (ChangedBy) REFERENCES AppUsers(UserID);
GO

-- 5. ADVANCED LOGIC & TRIGGERS
-- QUAN TR?NG: Ph?i có GO ngay tr??c l?nh :r ch?a Trigger

PRINT '--> 6. MaterialQC.sql...'
GO -- <== CÁI NÀY S?A L?I MSG 111
:r $(path)\MaterialQC.sql
GO

PRINT '--> 7. AdvancedLogic.sql...'
GO -- <== CÁI NÀY S?A L?I MSG 111
:r $(path)\AdvancedLogic.sql
GO

PRINT '--> 8. Immutability.sql...'
GO -- <== CÁI NÀY S?A L?I MSG 111
:r $(path)\Immutability.sql
GO

PRINT '--> 9. AuditTrail.sql...'
GO -- <== CÁI NÀY S?A L?I MSG 111
:r $(path)\AuditTrail.sql
GO

PRINT '--- HOAN TAT TOAN BO - HE THONG DA SAN SANG 100% ---'