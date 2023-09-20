CREATE PROCEDURE [dbo].[GetVisitRecordCompletedChecksByID]

	@CompletedChecksID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Checks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Checks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCompletedChecks


SELECT @Description = [Description]
FROM VRSCompletedChecks
JOIN @Checks AS Checks ON Checks.[ID] = CompletedChecksID
WHERE CompletedChecksID = @CompletedChecksID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCompletedChecksByID] TO PUBLIC
    AS [dbo];

