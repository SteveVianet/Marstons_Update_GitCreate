CREATE PROCEDURE [dbo].[GetVisitRecordFurtherActionByID]

	@FurtherActionID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @FurtherAction AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @FurtherAction EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSFurtherAction


SELECT @Description = [Description]
FROM VRSFurtherAction
JOIN @FurtherAction AS FurtherAction ON FurtherAction.[ID] = FurtherActionID
WHERE FurtherActionID = @FurtherActionID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordFurtherActionByID] TO PUBLIC
    AS [dbo];

