-- ============================================================================
-- 📜 MODULE: NHẬT KÝ HỆ THỐNG (SYSTEM AUDIT LOGS)
-- 
-- Chứa bảng tổng hợp mọi hành động thay đổi dữ liệu của người dùng.
-- Đáp ứng yêu cầu truy vết ngược (Traceability) của GMP.
-- ============================================================================

CREATE TABLE SystemAuditLog (
    AuditId BIGINT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100),         -- Tên bảng bị thay đổi
    RecordId NVARCHAR(100),          -- ID của bản ghi bị thay đổi
    Action NVARCHAR(50),             -- Hành động (Thêm, Sửa, Xóa)
    OldValue NVARCHAR(MAX),          -- Giá trị cũ (vd: JSON hoặc text)
    NewValue NVARCHAR(MAX),          -- Giá trị mới
    ChangedBy INT REFERENCES AppUsers(UserId), -- Người thay đổi
    ChangedDate DATETIME2 DEFAULT GETDATE()   -- Ngày giờ thay đổi
);
GO
