
CREATE PROCEDURE [dbo].[GetVisitRecordCompletedChecksByDescription]

	@CompletedChecksDescription VARCHAR(1000),
	@ID INT OUTPUT

AS

SET NOCOUNT ON

DECLARE @Checks AS TABLE ([ID] INT, [Description] NVARCHAR(100))
INSERT INTO @Checks EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSCompletedChecks

SELECT @ID = [ID]
FROM VRSCompletedChecks
JOIN @Checks AS Checks ON Checks.[ID] = CompletedChecksID
WHERE [Description] = @CompletedChecksDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitRecordCompletedChecksByDescription] TO PUBLIC
    AS [dbo];

