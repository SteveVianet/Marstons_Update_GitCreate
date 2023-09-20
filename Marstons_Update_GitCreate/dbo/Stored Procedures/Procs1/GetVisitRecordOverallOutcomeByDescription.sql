
CREATE PROCEDURE [dbo].[GetVisitRecordOverallOutcomeByDescription]

	@OverallOutcomeDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Outcome AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Outcome EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSVisitOutcome

SELECT @ID = [ID]
FROM VRSVisitOutcome
JOIN @Outcome AS Outcome ON Outcome.[ID] = VisitOutcomeID
WHERE [Description] = @OverallOutcomeDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordOverallOutcomeByDescription] TO PUBLIC
    AS [dbo];

