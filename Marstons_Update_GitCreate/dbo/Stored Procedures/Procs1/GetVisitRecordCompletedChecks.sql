CREATE PROCEDURE [dbo].[GetVisitRecordCompletedChecks]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Checks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Checks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCompletedChecks

SELECT CompletedChecksID, [Description]
FROM VRSCompletedChecks
JOIN @Checks AS Checks ON Checks.[ID] = CompletedChecksID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCompletedChecks] TO PUBLIC
    AS [dbo];

