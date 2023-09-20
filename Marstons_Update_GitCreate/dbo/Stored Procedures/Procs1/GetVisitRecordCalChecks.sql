CREATE PROCEDURE [dbo].[GetVisitRecordCalChecks]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Checks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Checks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted

SELECT CalChecksCompletedID, [Description]
FROM VRSCalChecksCompleted
JOIN @Checks AS Checks ON Checks.[ID] = CalChecksCompletedID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCalChecks] TO PUBLIC
    AS [dbo];

