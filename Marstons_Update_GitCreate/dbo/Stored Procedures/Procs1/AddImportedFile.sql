CREATE PROCEDURE [dbo].[AddImportedFile]
(
	@FileName 	VARCHAR(255), 
	@StartID	INT,
	@EndID	INT,
	@FileType	INT,
	@ID		INT OUTPUT
)

AS

INSERT INTO dbo.ImportedFiles
(FileName, Type, StartID, EndID)
VALUES
(@FileName, @FileType, @StartID, @EndID)

SET @ID = @@IDENTITY
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddImportedFile] TO PUBLIC
    AS [dbo];

