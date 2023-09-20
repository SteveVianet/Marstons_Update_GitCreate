
CREATE PROCEDURE [dbo].[GetVisitRecordActionsTakenByDescription]

	@ActionDescription 	VARCHAR(1000),
	@ID	INT OUTPUT

AS

CREATE TABLE #Actions ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO #Actions EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSActionsTaken

SELECT @ID = [ID]
FROM VRSActionTakenByBDM
JOIN #Actions AS Actions ON Actions.[ID] = ActionTakenID
WHERE [Description] = @ActionDescription

DROP TABLE #Actions

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordActionsTakenByDescription] TO PUBLIC
    AS [dbo];

