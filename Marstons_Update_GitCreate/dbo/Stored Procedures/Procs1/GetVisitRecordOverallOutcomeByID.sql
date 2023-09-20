CREATE PROCEDURE [dbo].[GetVisitRecordOverallOutcomeByID]

	@OverallOutcomeID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Outcome AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Outcome EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVisitOutcome


SELECT @Description = [Description]
FROM VRSVisitOutcome
JOIN @Outcome AS Outcome ON Outcome.[ID] = VisitOutcomeID
WHERE VisitOutcomeID = @OverallOutcomeID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordOverallOutcomeByID] TO PUBLIC
    AS [dbo];

