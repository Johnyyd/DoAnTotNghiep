-- ============================================================================
-- ðŸ­ MODULE: THI CÃ”NG Sáº¢N XUáº¤T (PRODUCTION EXECUTION)
-- 
-- Quáº£n lÃ½ Lá»‡nh sáº£n xuáº¥t (Production Orders) vÃ  cÃ¡c Máº» sáº£n xuáº¥t (Batches).
-- Äáº£m báº£o tÃ­nh chÃ­nh xÃ¡c cá»§a sá»‘ lÆ°á»£ng vÃ  thá»i gian thá»±c hiá»‡n.
-- ============================================================================

-- 1. Lá»†NH Sáº¢N XUáº¤T (Production Orders)
CREATE TABLE ProductionOrders (
    OrderId INT PRIMARY KEY IDENTITY(1,1),
    OrderCode VARCHAR(50) NOT NULL UNIQUE, -- MÃ£ lá»‡nh (vd: PO-2026-001)
    RecipeId INT REFERENCES Recipes(RecipeId),
    PlannedQuantity DECIMAL(18, 4) NOT NULL, -- Sá»‘ lÆ°á»£ng dá»± kiáº¿n sáº£n xuáº¥t
    ActualQuantity DECIMAL(18, 4),           -- Sá»‘ lÆ°á»£ng thá»±c táº¿ thu há»“i
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2,
    Status NVARCHAR(50) DEFAULT 'Draft',    -- Tráº¡ng thÃ¡i (Draft, Approved, InProcess, Completed, Hold, Cancelled)
    CreatedBy INT REFERENCES AppUsers(UserId),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    Note NVARCHAR(500)
);

-- 2. Máºº Sáº¢N XUáº¤T (Production Batches)
-- Má»™t Lá»‡nh sáº£n xuáº¥t cÃ³ thá»ƒ chia thÃ nh nhiá»u Máº» (Batch).
CREATE TABLE ProductionBatches (
    BatchId INT PRIMARY KEY IDENTITY(1,1),
    OrderId INT REFERENCES ProductionOrders(OrderId),
    BatchNumber VARCHAR(50) NOT NULL UNIQUE, -- Sá»‘ lÃ´ (vd: 112026)
    Status NVARCHAR(50) DEFAULT 'Scheduled', -- Tráº¡ng thÃ¡i lÃ´ (Scheduled, InProcess, Completed, OnHold)
    ManufactureDate DATETIME2,
    EndTime DATETIME2,                       -- Thá»i Ä‘iá»ƒm káº¿t thÃºc máº»
    ExpiryDate DATETIME2,
    CurrentStep INT DEFAULT 1,              -- BÆ°á»›c hiá»‡n táº¡i trong quy trÃ¬nh
    CreatedAt DATETIME2 DEFAULT GETDATE()
);

-- 3. NHáº¬T KÃ CÃ”NG ÄOáº N (Batch Process Logs)
-- Ghi láº¡i má»i hoáº¡t Ä‘á»™ng thá»±c táº¿ diá»…n ra trong quÃ¡ trÃ¬nh sáº£n xuáº¥t.
CREATE TABLE BatchProcessLogs (
    LogId BIGINT PRIMARY KEY IDENTITY(1,1),
    BatchId INT REFERENCES ProductionBatches(BatchId),
    RoutingId INT REFERENCES RecipeRouting(RoutingId), -- LiÃªn káº¿t cá»©ng vá»›i cÃ´ng Ä‘oáº¡n quy trÃ¬nh
    EquipmentId INT REFERENCES Equipments(EquipmentId),
    OperatorId INT REFERENCES AppUsers(UserId),
    StartTime DATETIME2,
    EndTime DATETIME2,
    ResultStatus NVARCHAR(50),               -- Tráº¡ng thÃ¡i káº¿t quáº£ (Passed, Failed, PendingQC)
    ParametersData NVARCHAR(MAX),            -- Dá»¯ liá»‡u JSON thÃ´ng sá»‘ váº­n hÃ nh mÃ¡y
    Notes NVARCHAR(MAX),
    IsDeviation BIT DEFAULT 0,               -- ÄÃ¡nh dáº¥u náº¿u cÃ³ sai lá»‡ch thÃ´ng sá»‘
    VerifiedById INT REFERENCES AppUsers(UserId), -- NgÆ°á»i tháº©m Ä‘á»‹nh (QA/QC)
    VerifiedDate DATETIME2,                  -- NgÃ y tháº©m Ä‘á»‹nh
    NumberOfRouting INT DEFAULT 1,           -- Sá»‘ láº§n thá»±c thi thá»±c táº¿ cá»§a cÃ¹ng 1 routing
    CONSTRAINT CK_BatchProcessLogs_NumberOfRouting CHECK (NumberOfRouting >= 1)
);
GO  

-- 4. GIÃ TRá»Š THá»°C Táº¾ Cá»¦A THÃ”NG Sá» (Batch Process Parameter Values)
-- LÆ°u trá»¯ chi tiáº¿t tá»«ng giÃ¡ trá»‹ thÃ´ng sá»‘ Ä‘Ã£ tÃ¡ch tá»« JSON Ä‘á»ƒ phá»¥c vá»¥ bÃ¡o cÃ¡o/truy váº¥n.
CREATE TABLE BatchProcessParameterValue (
    ValueId BIGINT PRIMARY KEY IDENTITY(1,1),
    LogId BIGINT REFERENCES BatchProcessLogs(LogId), -- Tham chiáº¿u tá»›i nháº­t kÃ½ cÃ´ng Ä‘oáº¡n
    ParameterId INT REFERENCES StepParameters(ParameterId), -- Tham chiáº¿u tá»›i Ä‘á»‹nh nghÄ©a thÃ´ng sá»‘
    ActualValue DECIMAL(18, 4),                     -- GiÃ¡ trá»‹ Ä‘o Ä‘Æ°á»£c thá»±c táº¿
    RecordedDate DATETIME2 DEFAULT GETDATE(),       -- Thá»i Ä‘iá»ƒm ghi nháº­n
    Note NVARCHAR(500)                              -- Ghi chÃº riÃªng cho tá»«ng thÃ´ng sá»‘ (náº¿u cÃ³)
);
GO
