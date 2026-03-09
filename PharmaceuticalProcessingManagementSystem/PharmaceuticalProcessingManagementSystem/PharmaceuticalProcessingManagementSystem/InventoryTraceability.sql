-- Qu?n lý lô nguyên li?u nh?p kho (??u vào)
CREATE TABLE InventoryLots (
    LotID INT PRIMARY KEY IDENTITY(1,1),
    MaterialID INT REFERENCES Materials(MaterialID),
    LotNumber VARCHAR(50) NOT NULL, -- S? lô nhà cung c?p
    QuantityCurrent DECIMAL(18, 4) NOT NULL,
    ManufactureDate DATETIME2,
    ExpiryDate DATETIME2 NOT NULL,
    QCStatus NVARCHAR(50) DEFAULT 'Quarantine' -- Quarantine (Bi?t tr?), Released (??t), Rejected (H?y)
);

-- C?p phát nguyên li?u (Material Dispensing/Usage) - KEY C?A TRUY XU?T
-- B?ng này tr? l?i câu h?i: Viên thu?c này làm t? lô b?t mì nào?
CREATE TABLE MaterialUsage (
    UsageID BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchID INT REFERENCES ProductionBatches(BatchID), -- Dùng cho m? nào
    InventoryLotID INT REFERENCES InventoryLots(LotID), -- L?y t? lô nguyên li?u nào
    PlannedAmount DECIMAL(18, 4), -- S? l??ng theo công th?c
    ActualAmount DECIMAL(18, 4) NOT NULL, -- S? l??ng th?c t? ?? vào n?i
    DispensedBy INT, -- Ng??i cân/c?p phát
    Timestamp DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(200)
);