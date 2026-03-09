-- B?ng Audit Log chung cho toàn h? th?ng
CREATE TABLE SystemAuditLog (
    AuditID BIGINT PRIMARY KEY IDENTITY(1,1),
    TableName VARCHAR(100),
    RecordID VARCHAR(50),
    Action NVARCHAR(10) CHECK (Action IN ('INSERT', 'UPDATE', 'DELETE')),
    OldValue NVARCHAR(MAX), -- L?u JSON d? li?u c?
    NewValue NVARCHAR(MAX), -- L?u JSON d? li?u m?i
    ChangedBy INT,
    ChangedDate DATETIME2 DEFAULT GETDATE()
);