
CREATE PROCEDURE [dbo].[GetVisitRecordFurtherActionByDescription]

	@FurtherActionDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @FurtherAction AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @FurtherAction EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSFurtherAction

SELECT @ID = [ID]
FROM VRSFurtherAction
JOIN @FurtherAction AS FurtherAction ON FurtherAction.[ID] = FurtherActionID
WHERE [Description] = @FurtherActionDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordFurtherActionByDescription] TO PUBLIC
    AS [dbo];

