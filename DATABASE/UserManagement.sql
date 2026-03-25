-- ============================================================================
-- 👤 MODULE: QUẢN LÝ NGƯỜI DÙNG (USER MANAGEMENT)
-- 
-- Quản lý tài khoản, vai trò (Roles) và thông tin cá nhân của nhân viên.
-- Đảm bảo tính bảo mật và phân quyền trong nhà máy dược.
-- ============================================================================

CREATE TABLE AppUsers (
    UserId INT PRIMARY KEY IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE, -- Tên đăng nhập
    FullName NVARCHAR(100) NOT NULL,      -- Họ tên đầy đủ nhân viên
    Role NVARCHAR(50) NOT NULL,          -- Vai trò (Admin, QA_QC, Operator, ProductionManager)
    IsActive BIT DEFAULT 1,               -- Trạng thái hoạt động (1: Đang làm, 0: Nghỉ việc)
    PasswordHash NVARCHAR(MAX),          -- Mật khẩu mã hóa (BCrypt)
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    LastLogin DATETIME2
);
GO
