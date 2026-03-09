-- File: UserManagement.sql
-- 1. B?ng Ng??i dùng h? th?ng
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AppUsers]') AND type in (N'U'))
BEGIN
    CREATE TABLE AppUsers (
        UserID INT PRIMARY KEY IDENTITY(1,1),
        Username VARCHAR(50) NOT NULL UNIQUE,
        FullName NVARCHAR(100) NOT NULL,
        Role NVARCHAR(20) CHECK (Role IN ('Admin', 'QA_QC', 'ProductionManager', 'Operator', 'Storekeeper')),
        IsActive BIT DEFAULT 1,
        CreatedAt DATETIME2 DEFAULT GETDATE()
    );

    -- 2. Thêm d? li?u m?u
    INSERT INTO AppUsers (Username, FullName, Role) VALUES ('admin', N'Qu?n tr? viên', 'Admin');
    INSERT INTO AppUsers (Username, FullName, Role) VALUES ('truong_kho', N'Nguy?n V?n A', 'Storekeeper');
    INSERT INTO AppUsers (Username, FullName, Role) VALUES ('qa_manager', N'Tr?n Th? B', 'QA_QC');
    INSERT INTO AppUsers (Username, FullName, Role) VALUES ('system_bot', N'H? th?ng T? ??ng', 'Admin');
END
GO