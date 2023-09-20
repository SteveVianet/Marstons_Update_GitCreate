CREATE PROCEDURE [dbo].[GetVisitRecordOverallOutcome]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Outcome AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Outcome EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVisitOutcome

SELECT VisitOutcomeID, [Description]
FROM VRSVisitOutcome
JOIN @Outcome AS Outcome ON Outcome.[ID] = VisitOutcomeID
WHERE Depricated = 0 OR @IncludeDepricated = 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordOverallOutcome] TO PUBLIC
    AS [dbo];

