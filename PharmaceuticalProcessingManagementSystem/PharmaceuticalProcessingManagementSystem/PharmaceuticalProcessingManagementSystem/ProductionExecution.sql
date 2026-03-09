-- L?nh s?n xu?t (Production Order)
CREATE TABLE ProductionOrders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE, -- Mã l?nh (t? sinh)
    RecipeID INT REFERENCES Recipes(RecipeID), -- Tham chi?u công th?c g?c
    PlannedQuantity DECIMAL(18, 4) NOT NULL,
    ActualQuantity DECIMAL(18, 4),
    StartDate DATETIME2,
    EndDate DATETIME2,
    -- Tr?ng thái quan tr?ng trong ?nh ?? bài
    Status NVARCHAR(50) CHECK (Status IN ('Draft', 'Approved', 'In-Process', 'Hold', 'Completed', 'Cancelled')),
    CreatedBy INT,
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- M? s?n xu?t (Production Batch) - M?t l?nh có th? chia làm nhi?u m? nh?
CREATE TABLE ProductionBatches (
    BatchID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT REFERENCES ProductionOrders(OrderID),
    BatchNumber VARCHAR(50) NOT NULL UNIQUE, -- S? lô (QUAN TR?NG NH?T ?? TRUY XU?T)
    ManufactureDate DATETIME2 DEFAULT GETDATE(),
    EndTime DATETIME2,
    ExpiryDate DATETIME2, -- H?n s? d?ng
    CurrentStep INT DEFAULT 0, -- ?ang ? b??c nào
    Status NVARCHAR(50) DEFAULT 'Queued'
);

---- Thêm c?t EndTime vào b?ng ProductionBatches
--ALTER TABLE ProductionBatches
--ADD EndTime DATETIME2 NULL;

PRINT '>>> ?ã c?p nh?t Database thành công! <<<';

-- Theo dõi ti?n ?? t?ng công ?o?n (Tracking)
CREATE TABLE BatchProcessLogs (
    LogID BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchID INT REFERENCES ProductionBatches(BatchID),
    RoutingID INT REFERENCES RecipeRouting(RoutingID), -- ?ang làm b??c nào theo thi?t k?
    EquipmentID INT REFERENCES Equipments(EquipmentID), -- Th?c t? làm máy nào
    OperatorID INT, -- Ng??i v?n hành
    StartTime DATETIME2,
    EndTime DATETIME2,
    ResultStatus NVARCHAR(50) CHECK (ResultStatus IN ('Passed', 'Failed', 'PendingQC')),
    ParametersData JSON -- C?t m? r?ng l?u các thông s? c?m bi?n (Nhi?t ??, ?? ?m th?c t?)
);

SELECT * FROM ProductionOrders;