CREATE PROCEDURE [dbo].[GetVisitRecordCalChecksByID]

	@CalCheckID INT,
	@Description NVARCHAR(100) OUTPUT

AS

SET NOCOUNT ON

DECLARE @CalChecks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @CalChecks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCalChecksCompleted


SELECT @Description = [Description]
FROM VRSCalChecksCompleted
JOIN @CalChecks AS CalChecks ON CalChecks.[ID] = CalChecksCompletedID
WHERE CalChecksCompletedID = @CalCheckID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCalChecksByID] TO PUBLIC
    AS [dbo];

