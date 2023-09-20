
CREATE PROCEDURE dbo.GetWebSiteOpenCallLineFaults
(
	@EDISID INT
)
AS

SELECT ID, EDISID, CallFaults.CallID, AdditionalInfo FROM CallFaults 
JOIN (
	SELECT Calls.EDISID, Calls.ID AS CallID FROM Calls
	LEFT JOIN (
		SELECT MAX(ID) AS ID, CallID FROM CallStatusHistory
		GROUP BY CallID) AS LatestStatus ON LatestStatus.CallID = Calls.ID
	JOIN CallStatusHistory ON CallStatusHistory.ID = LatestStatus.ID
	WHERE CallStatusHistory.StatusID NOT IN (4,5)
	AND Calls.EDISID = @EDISID) AS OpenCalls ON OpenCalls.CallID = CallFaults.CallID
WHERE FaultTypeID = 33


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteOpenCallLineFaults] TO PUBLIC
    AS [dbo];

