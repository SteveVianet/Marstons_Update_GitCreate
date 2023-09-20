CREATE PROCEDURE [dbo].[AddImportedFileLogDetail]
(
    @FileID INT,
    @FileNumber INT,
    @Success BIT,
    @Details VARCHAR(4000)
)
AS

INSERT INTO [dbo].[ImportedFileLogDetail] ([ImportedFileLogID], [FileNumber], [Success], [Details])
VALUES (@FileID, @FileNumber, @Success, @Details)

SET @FileID = @@IDENTITY
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddImportedFileLogDetail] TO PUBLIC
    AS [dbo];

