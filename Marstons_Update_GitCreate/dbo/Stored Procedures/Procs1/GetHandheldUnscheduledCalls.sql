CREATE PROCEDURE [dbo].[GetHandheldUnscheduledCalls]
(
	@CallID		INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT	@DatabaseID AS DatabaseID, Calls.[ID] AS CallID, EngineerID
FROM CallStatusHistory
JOIN
(
SELECT CallID, MAX([ID]) AS LatestID
FROM CallStatusHistory
GROUP BY CallID
) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
AND LatestCallChanges.[LatestID] = CallStatusHistory.[ID]
JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
WHERE StatusID = 1
AND (Calls.POStatusID IN (1, 4) OR Calls.AuthorisationRequired = 0)
AND (VisitedOn IS NULL OR YEAR(VisitedOn) < 1950)
AND (CallStatusHistory.CallID = @CallID OR @CallID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHandheldUnscheduledCalls] TO PUBLIC
    AS [dbo];

