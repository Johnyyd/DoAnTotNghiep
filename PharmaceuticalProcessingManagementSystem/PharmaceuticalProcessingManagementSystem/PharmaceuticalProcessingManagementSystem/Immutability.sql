CREATE TRIGGER trg_Prevent_Edit_Approved_Recipe
ON Recipes
FOR UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Deleted WHERE Status = 'Approved')
    BEGIN
        RAISERROR ('Không th? s?a ho?c xóa Công th?c ?ã ???c Duy?t (Approved). Hãy t?o Version m?i.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;