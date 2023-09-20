
CREATE PROCEDURE [dbo].[GetVisitRecordCalChecksByDescription]

	@CalCheckDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @CalChecks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @CalChecks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted

SELECT @ID = [ID]
FROM VRSCalChecksCompleted
JOIN @CalChecks AS CalChecks ON CalChecks.[ID] = CalChecksCompletedID
WHERE [Description] = @CalCheckDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCalChecksByDescription] TO PUBLIC
    AS [dbo];

