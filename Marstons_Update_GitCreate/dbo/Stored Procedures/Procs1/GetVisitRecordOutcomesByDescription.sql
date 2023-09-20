
CREATE PROCEDURE [dbo].[GetVisitRecordOutcomesByDescription]

	@OutcomeDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

CREATE TABLE #Outcomes ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #Outcomes EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSOutcomes

SELECT @ID = [ID]
FROM VisitRecordOutcomes
JOIN #Outcomes AS Outcomes ON Outcomes.[ID] = OutcomeID
WHERE [Description] = @OutcomeDescription

DROP TABLE #Outcomes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordOutcomesByDescription] TO PUBLIC
    AS [dbo];

