CREATE PROCEDURE [dbo].[GetImportedVisitNoteDetails]
(
    @FileID INT = NULL,
    @Filename VARCHAR(255) = NULL
)
AS

SELECT
    [Note].[ID],
    [Note].[Filename],
    [Detail].[FileNumber],
    [Detail].[Success],
    [Detail].Details
FROM [dbo].[ImportedVisitNotes] AS [Note]
JOIN [dbo].[ImportedVisitNoteDetails] AS [Detail] ON [Note].[ID] = [Detail].[ImportedVisitNoteID]
WHERE 
    (@FileID IS NULL OR [Note].[ID] = @FileID)
AND (@Filename IS NULL OR [Note].[Filename] = @Filename)