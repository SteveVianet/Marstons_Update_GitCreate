CREATE PROCEDURE [dbo].[AddImportedVisitNoteDetail]
(
    @FileID INT,
    @FileNumber INT,
    @Success BIT,
    @Details VARCHAR(4000)
)
AS

INSERT INTO [dbo].[ImportedVisitNoteDetails] ([ImportedVisitNoteID], [FileNumber], [Success], [Details])
VALUES (@FileID, @FileNumber, @Success, @Details)
