-- File: AdvancedLogic.sql

-- TRIGGER 1: Ch?n dùng máy ?ang b?o trì
CREATE TRIGGER trg_Check_Equipment_Status
ON BatchProcessLogs
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Inserted i
        JOIN Equipments e ON i.EquipmentID = e.EquipmentID
        WHERE e.Status = 'Maintenance'
    )
    BEGIN
        RAISERROR ('L?i GMP: Không th? s? d?ng thi?t b? ?ang B?o trì (Maintenance).', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO -- <=== QUAN TR?NG: L?nh GO này s?a l?i Msg 111

-- TRIGGER 2: Ch?ng nh?m nguyên li?u
CREATE TRIGGER trg_Validate_Material_Usage
ON MaterialUsage
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Inserted i
        JOIN InventoryLots lot ON i.InventoryLotID = lot.LotID 
        JOIN ProductionBatches batch ON i.BatchID = batch.BatchID
        JOIN ProductionOrders ord ON batch.OrderID = ord.OrderID
        WHERE lot.MaterialID NOT IN (
            SELECT bom.MaterialID 
            FROM RecipeBOM bom 
            WHERE bom.RecipeID = ord.RecipeID
        )
    )
    BEGIN
        RAISERROR ('L?i Nghiêm Tr?ng: Nguyên li?u c?p phát không có trong Công th?c (BOM)!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO