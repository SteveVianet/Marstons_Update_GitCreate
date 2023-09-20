CREATE PROCEDURE [dbo].[GetImportedFileLogDetails]
(
    @FileID INT = NULL,
    @Filename VARCHAR(255) = NULL
)
AS


IF (@Filename IS NOT NULL)
BEGIN
    SELECT TOP 1 @FileID = [Note].[ID]
    FROM [dbo].[ImportedFileLog] AS [Note]
    ORDER BY [ID] DESC
END

SELECT
    [Note].[ID],
    [Note].[Filename],
    [Detail].[FileNumber],
    [Detail].[Success],
    [Detail].Details
FROM [dbo].[ImportedFileLog] AS [Note]
JOIN [dbo].[ImportedFileLogDetail] AS [Detail] ON [Note].[ID] = [Detail].[ImportedFileLogID]
WHERE 
    (@FileID IS NULL OR [Note].[ID] = @FileID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetImportedFileLogDetails] TO PUBLIC
    AS [dbo];

