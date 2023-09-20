CREATE PROCEDURE [dbo].[GetVisitRecordActionsTakenByID]

	@ActionID 	INT,
	@Description	NVARCHAR(100) OUTPUT

AS

DECLARE @Actions AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Actions EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSActionsTaken

SELECT @Description = [Description]
FROM VRSActionTakenByBDM
JOIN @Actions AS Actions ON Actions.[ID] = ActionTakenID
WHERE ActionTakenID = @ActionID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordActionsTakenByID] TO PUBLIC
    AS [dbo];

