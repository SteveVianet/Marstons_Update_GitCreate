CREATE PROCEDURE [dbo].[GetVisitRecordOutcomes]

AS

SET NOCOUNT ON

CREATE TABLE #Outcomes ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #Outcomes EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSOutcomes

SELECT OutcomeID, [Description]
FROM VisitRecordOutcomes
JOIN #Outcomes AS Outcomes ON Outcomes.[ID] = OutcomeID

DROP TABLE #Outcomes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordOutcomes] TO PUBLIC
    AS [dbo];

