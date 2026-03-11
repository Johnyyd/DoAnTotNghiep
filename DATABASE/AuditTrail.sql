CREATE TRIGGER trg_Recipes_Audit
ON Recipes
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO SystemAuditLog (TableName, RecordID, Action, OldValue, NewValue, ChangedDate)
    SELECT 
        'Recipes',
        CAST(d.RecipeID AS VARCHAR(50)),
        CASE WHEN i.RecipeID IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
        (SELECT * FROM Deleted d FOR JSON AUTO), -- L?u d? li?u c? d??i d?ng JSON
        (SELECT * FROM Inserted i FOR JSON AUTO), -- L?u d? li?u m?i d??i d?ng JSON
        GETDATE()
    FROM Deleted d
    LEFT JOIN Inserted i ON d.RecipeID = i.RecipeID;
END;