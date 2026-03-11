-- B?ng quy ??i ??n v? (Ví d?: 1 kg = 1000 g)
CREATE TABLE UomConversions (
    ConversionID INT PRIMARY KEY IDENTITY(1,1),
    FromUomID INT REFERENCES UnitOfMeasure(UomID),
    ToUomID INT REFERENCES UnitOfMeasure(UomID),
    Factor DECIMAL(18, 6) NOT NULL, -- H? s? nhân. VD: T? kg sang g là 1000
    CONSTRAINT UQ_Conversion UNIQUE (FromUomID, ToUomID)
);

USE [PharmaceuticalProcessingManagementSystem];
GO

INSERT INTO UnitOfMeasure (UomName, Description) VALUES 
(N'kg', N'Kilogram'),
(N'g', N'Gram'),
(N'mg', N'Milligram'),
(N'L', N'Liter'),
(N'ml', N'Milliliter'),
(N'vien', N'Viên (Tablet)'),
(N'vi', N'V? (Blister)'),
(N'thung', N'Thùng (Carton)');
GO

SELECT * FROM UnitOfMeasure