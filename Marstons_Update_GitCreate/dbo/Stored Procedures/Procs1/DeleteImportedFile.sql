CREATE PROCEDURE [dbo].[DeleteImportedFile]
(
	@ID		INT
)

AS

DECLARE @StartID INT
DECLARE @EndID INT

SELECT    @StartID = StartID,
            @EndID = EndID
FROM dbo.ImportedFiles
WHERE [ID] = @ID
 
BEGIN TRAN
 
DELETE FROM dbo.Delivery
WHERE [ID] BETWEEN @StartID AND @EndID
 
UPDATE dbo.ImportedFiles
SET Deleted = 1, DeletedBy = SUSER_SNAME(), DeletedDate = GETDATE()
WHERE [ID] = @ID
 
COMMIT
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteImportedFile] TO PUBLIC
    AS [dbo];

