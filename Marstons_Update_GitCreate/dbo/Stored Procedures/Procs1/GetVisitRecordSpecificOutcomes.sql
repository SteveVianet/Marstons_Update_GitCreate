CREATE PROCEDURE [dbo].[GetVisitRecordSpecificOutcomes]
	@IncludeDepricated BIT = 1
AS

SET NOCOUNT ON

DECLARE @Outcomes AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Outcomes EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSOutcomes

SELECT SpecificOutcomeID, [Description]
FROM VRSSpecificOutcome
JOIN @Outcomes AS Outcomes ON Outcomes.[ID] = SpecificOutcomeID
WHERE Depricated = 0 OR @IncludeDepricated = 1