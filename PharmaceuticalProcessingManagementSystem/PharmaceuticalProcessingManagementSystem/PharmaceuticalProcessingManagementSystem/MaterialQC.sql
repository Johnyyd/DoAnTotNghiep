CREATE TRIGGER trg_Check_Material_QC
ON MaterialUsage
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Inserted i
        JOIN InventoryLots l ON i.InventoryLotID = l.LotID
        WHERE l.QCStatus <> 'Released' OR l.ExpiryDate < GETDATE()
    )
    BEGIN
        RAISERROR ('L?i GMP: Không th? c?p phát nguyên li?u ch?a ??t QC (Released) ho?c ?ã h?t h?n.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;