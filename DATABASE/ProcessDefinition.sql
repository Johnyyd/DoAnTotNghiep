-- ============================================================================
-- ðŸ“ MODULE: Äá»ŠNH NGHÄ¨A QUY TRÃŒNH & CÃ”NG THá»¨C (RECIPES & BOM)
-- 
-- Theo GMP, má»i sáº£n pháº©m pháº£i cÃ³ cÃ´ng thá»©c chÃ­nh (Master Recipe) 
-- vÃ  Ä‘á»‹nh má»©c váº­t tÆ° (BOM) Ä‘Æ°á»£c phÃª duyá»‡t bá»Ÿi bá»™ pháº­n QA.
-- ============================================================================

-- 1. CÃ”NG THá»¨C CHÃNH (Recipes)
CREATE TABLE Recipes (
    RecipeId INT PRIMARY KEY IDENTITY(1,1),
    MaterialId INT REFERENCES Materials(MaterialId), -- Sáº£n pháº©m Ä‘áº§u ra
    VersionNumber INT DEFAULT 1,                      -- PhiÃªn báº£n cÃ´ng thá»©c
    BatchSize DECIMAL(18, 2) NOT NULL,               -- Cá»¡ máº» tiÃªu chuáº©n (vd: 100 kg)
    Status NVARCHAR(50) DEFAULT 'Draft',            -- Tráº¡ng thÃ¡i (NhÃ¡p, ÄÃ£ phÃª duyá»‡t, Háº¿t hiá»‡u lá»±c)
    ApprovedBy INT REFERENCES AppUsers(UserId),       -- NgÆ°á»i phÃª duyá»‡t (QA/QC)
    ApprovedDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    EffectiveDate DATETIME2,                          -- NgÃ y cÃ³ hiá»‡u lá»±c
    Note NVARCHAR(500)
);

-- 2. Äá»ŠNH Má»¨C NGUYÃŠN Váº¬T LIá»†U (Recipe BOM)
-- Chi tiáº¿t tá»«ng thÃ nh pháº§n Ä‘á»ƒ táº¡o ra sáº£n pháº©m.
CREATE TABLE RecipeBom (
    BomId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    MaterialId INT REFERENCES Materials(MaterialId), -- NguyÃªn váº­t liá»‡u thÃ nh pháº§n
    Quantity DECIMAL(18, 4) NOT NULL,               -- LÆ°á»£ng yÃªu cáº§u
    UomId INT REFERENCES UnitOfMeasure(UomId),       -- ÄÆ¡n vá»‹ tÃ­nh cá»§a nguyÃªn liá»‡u
    WastePercentage DECIMAL(5, 2) DEFAULT 0,         -- Tá»· lá»‡ hao há»¥t cho phÃ©p (%)
    Note NVARCHAR(200)
);

-- 3. CÃC BÆ¯á»šC CÃ”NG ÄOáº N (Recipe Routing)
-- Quy trÃ¬nh sáº£n xuáº¥t tá»«ng bÆ°á»›c (vd: CÃ¢n, Trá»™n, Sáº¥y...).
CREATE TABLE RecipeRouting (
    RoutingId INT PRIMARY KEY IDENTITY(1,1),
    RecipeId INT REFERENCES Recipes(RecipeId),
    StepNumber INT NOT NULL,                        -- Sá»‘ thá»© tá»± bÆ°á»›c (1, 2, 3...)
    StepName NVARCHAR(100) NOT NULL,                -- TÃªn bÆ°á»›c (vd: Trá»™n khÃ´)
    DefaultEquipmentId INT REFERENCES Equipments(EquipmentId), -- Thiáº¿t bá»‹ máº·c Ä‘á»‹nh
    EstimatedTimeMinutes INT,                      -- Thá»i gian dá»± kiáº¿n (phÃºt)
    Description NVARCHAR(500),                       -- Chi tiáº¿t ná»™i dung cÃ´ng viá»‡c
    NumberOfRouting INT DEFAULT 1,                  -- Sá»‘ attempt tá»‘i Ä‘a cho phÃ©p Ä‘á»‘i vá»›i cÃ´ng Ä‘oáº¡n nÃ y
    CONSTRAINT CK_RecipeRouting_NumberOfRouting CHECK (NumberOfRouting >= 1)
);
GO

-- 4. THÃ”NG Sá» KIá»‚M TRA CHO Tá»ªNG BÆ¯á»šC (Step Parameters)
-- Äá»‹nh nghÄ©a cÃ¡c ngÆ°á»¡ng Min/Max cho cÃ¡c thÃ´ng sá»‘ váº­n hÃ nh (Nhiá»‡t Ä‘á»™, tá»‘c Ä‘á»™...).
CREATE TABLE StepParameters (
    ParameterId INT PRIMARY KEY IDENTITY(1,1),
    RoutingId INT REFERENCES RecipeRouting(RoutingId), -- Tham chiáº¿u tá»›i bÆ°á»›c quy trÃ¬nh
    ParameterName NVARCHAR(100) NOT NULL,             -- TÃªn thÃ´ng sá»‘ (vd: Nhiá»‡t Ä‘á»™ sáº¥y)
    Unit NVARCHAR(50),                                -- ÄÆ¡n vá»‹ tÃ­nh (vd: Â°C, v/p)
    MinValue DECIMAL(18, 4),                          -- NgÆ°á»¡ng dÆ°á»›i cho phÃ©p
    MaxValue DECIMAL(18, 4),                          -- NgÆ°á»¡ng trÃªn cho phÃ©p
    IsCritical BIT DEFAULT 1,                         -- CÃ³ pháº£i thÃ´ng sá»‘ trá»ng yáº¿u (CCP) hay khÃ´ng
    Note NVARCHAR(200)                                -- Ghi chÃº hÆ°á»›ng dáº«n kiá»ƒm tra
);
GO
