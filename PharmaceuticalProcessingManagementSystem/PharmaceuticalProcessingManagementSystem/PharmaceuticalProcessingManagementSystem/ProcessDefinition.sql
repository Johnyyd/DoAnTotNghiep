-- Công th?c g?c (Header) - Qu?n lý theo Version
CREATE TABLE Recipes (
    RecipeID INT PRIMARY KEY IDENTITY(1,1),
    MaterialID INT REFERENCES Materials(MaterialID), -- S?n xu?t ra món gì
    VersionNumber INT NOT NULL, -- Phiên b?n 1, 2, 3...
    BatchSize DECIMAL(18, 4) NOT NULL, -- Kích th??c lô chu?n (VD: 100,000 viên)
    Status NVARCHAR(50) CHECK (Status IN ('Draft', 'PendingApproval', 'Approved', 'Obsolete')),
    ApprovedBy INT, -- ID ng??i duy?t (liên k?t b?ng User)
    ApprovedDate DATETIME2,
    CreatedAt DATETIME2,
    EffectiveDate DATETIME2, -- Ngày hi?u l?c
    Note NVARCHAR(MAX),
    -- Ràng bu?c: M?t s?n ph?m có th? có nhi?u version, nh?ng m?i version là duy nh?t
    CONSTRAINT UQ_Recipe_Version UNIQUE (MaterialID, VersionNumber)
);

--ALTER TABLE Recipes
--ADD CreatedAt DATETIME2 NULL;

-- BOM (Bill of Materials) - ??nh m?c nguyên li?u
CREATE TABLE RecipeBOM (
    BomID INT PRIMARY KEY IDENTITY(1,1),
    RecipeID INT REFERENCES Recipes(RecipeID),
    MaterialID INT REFERENCES Materials(MaterialID), -- Nguyên li?u c?n dùng
    Quantity DECIMAL(18, 6) NOT NULL, -- S? l??ng c?n cho 1 BatchSize chu?n
    UomID INT REFERENCES UnitOfMeasure(UomID),
    WastePercentage DECIMAL(5, 2) DEFAULT 0, -- T? l? hao h?t cho phép
    Note NVARCHAR(200)
);

-- Routing (Quy trình s?n xu?t) - Các b??c th?c hi?n
CREATE TABLE RecipeRouting (
    RoutingID INT PRIMARY KEY IDENTITY(1,1),
    RecipeID INT REFERENCES Recipes(RecipeID),
    StepNumber INT NOT NULL, -- B??c 10, 20, 30...
    StepName NVARCHAR(200) NOT NULL, -- Tr?n, D?p viên, Bao phim
    Description NVARCHAR(MAX), -- Mô t? k? thu?t (nhi?t ??, ?? ?m, t?c ?? máy)
    EstimatedTimeMinutes INT,
    DefaultEquipmentID INT REFERENCES Equipments(EquipmentID) -- Máy m?c ??nh
);

SELECT * FROM Recipes;