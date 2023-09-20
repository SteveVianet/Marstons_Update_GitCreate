CREATE PROCEDURE [dbo].[AddImportedFileLog]
(
    @Filename VARCHAR(255),
    @FileID INT OUTPUT
)
AS

INSERT INTO [dbo].[ImportedFileLog] ([Filename])
VALUES (@Filename)

SET @FileID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddImportedFileLog] TO PUBLIC
    AS [dbo];

