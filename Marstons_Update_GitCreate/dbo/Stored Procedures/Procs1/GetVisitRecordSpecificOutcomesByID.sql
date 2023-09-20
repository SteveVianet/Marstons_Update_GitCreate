CREATE PROCEDURE [dbo].[GetVisitRecordSpecificOutcomesByID]

	@SpecificOutcomeID INT,
	@OutcomeDescription NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @Outcomes AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Outcomes EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSSpecificOutcomes


SELECT @OutcomeDescription = [Description]
FROM VRSSpecificOutcome
JOIN @Outcomes AS Outcomes ON Outcomes.[ID] = SpecificOutcomeID
WHERE SpecificOutcomeID = @SpecificOutcomeID