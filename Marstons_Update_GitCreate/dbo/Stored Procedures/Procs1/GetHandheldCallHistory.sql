CREATE PROCEDURE [dbo].[GetHandheldCallHistory]
(
	@CallID INT
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @DatabaseID INT
DECLARE @SiteHistory TABLE(DatabaseID INT, EDISID INT, CallID INT, EngineerID INT, [Name] VARCHAR(100), Faults VARCHAR(8000), WorkDone VARCHAR(8000), WorkDetailComment VARCHAR(8000), TamperingID INT, VisitDate DATETIME, CalChecksCompletedID INT)

SELECT @EDISID = EDISID
FROM Calls
WHERE [ID] = @CallID

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @SiteHistory
SELECT @DatabaseID, EDISID, VisitRecords.[ID] AS VisitID, -1, Users.UserName, 'VRS Visit', NULL, NULL, TamperingID, VisitDate, CalChecksCompletedID
FROM VisitRecords
JOIN Users ON Users.[ID] = VisitRecords.CAMID
WHERE EDISID = @EDISID
AND CustomerID = 0
AND VisitRecords.Deleted = 0

INSERT INTO @SiteHistory
SELECT @DatabaseID AS DatabaseID,
	   Calls.EDISID,
	   Calls.[ID],
	   EngineerID,
	   NULL,
	   CASE WHEN Calls.UseBillingItems = 1 THEN dbo.udfConcatCallReasonsSingleLine(Calls.[ID]) ELSE dbo.udfConcatCallFaults(Calls.[ID]) END AS Faults,
	   dbo.GetWorkItemDescriptionFunction(Calls.[ID]) AS WorkDone,
	   CAST(CallWorkDetailComments.WorkDetailComment AS VARCHAR(8000)) AS WorkDetailComment,
	   NULL, VisitedOn, NULL
FROM Calls
LEFT JOIN (SELECT CallWorkDetailComments.CallID, MAX(CallWorkDetailComments.[ID]) AS [ID]
			FROM CallWorkDetailComments
			JOIN Calls ON Calls.[ID] = CallWorkDetailComments.CallID AND EDISID = @EDISID AND Calls.[ID] <> @CallID
			GROUP BY CallWorkDetailComments.CallID) 
		AS LatestWorkDetailComments ON LatestWorkDetailComments.CallID = Calls.[ID]
LEFT JOIN CallWorkDetailComments ON CallWorkDetailComments.[ID] = LatestWorkDetailComments.[ID]
WHERE Calls.EDISID = @EDISID
AND Calls.[ID] <> @CallID
AND AbortReasonID <> 3
ORDER BY Calls.[ID]

SELECT DatabaseID,
	   EDISID,
	   CallID,
	   EngineerID,
	   [Name],
	   Faults,
	   WorkDone,
	   WorkDetailComment,
	   TamperingID,
	   VisitDate,
	   CalChecksCompletedID
FROM @SiteHistory

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHandheldCallHistory] TO PUBLIC
    AS [dbo];

