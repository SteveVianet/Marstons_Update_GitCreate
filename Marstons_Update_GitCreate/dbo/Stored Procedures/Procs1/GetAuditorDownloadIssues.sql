CREATE PROCEDURE [dbo].[GetAuditorDownloadIssues]
AS

SET NOCOUNT ON

DECLARE @DownloadIssueSites TABLE(EDISID INT NOT NULL)
DECLARE @MaxCalls TABLE(EDISID INT NOT NULL, MaxCallID INT NOT NULL)

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @DownloadIssueSites
(EDISID)
SELECT EDISID 
FROM Sites
WHERE LastDownload < DATEADD(day, -1, GETDATE())
AND Hidden = 0

INSERT @MaxCalls
(EDISID, MaxCallID)
SELECT EDISID, MAX([ID])
FROM Calls
GROUP BY EDISID

SELECT @CustomerID AS Customer,
	   DownloadIssueSites.EDISID,
	   CASE WHEN OpenCalls.[ID] IS NULL THEN NULL ELSE dbo.GetCallReference(OpenCalls.[ID]) END AS CallRef
FROM @DownloadIssueSites AS DownloadIssueSites
LEFT JOIN (	SELECT Calls.EDISID, Calls.[ID], MAX(CallStatusHistory.StatusID) AS Status
			FROM Calls
			JOIN @DownloadIssueSites AS DownloadIssueSites ON DownloadIssueSites.EDISID = Calls.EDISID
			JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID] AND CallStatusHistory.StatusID <> 6
			GROUP BY Calls.EDISID, Calls.[ID]
			HAVING MAX(CallStatusHistory.StatusID) NOT IN (4, 5) 
		  ) AS OpenCalls ON OpenCalls.EDISID = DownloadIssueSites.EDISID
JOIN @MaxCalls AS MaxCalls ON MaxCalls.EDISID = OpenCalls.EDISID AND MaxCalls.MaxCallID = OpenCalls.[ID] OR OpenCalls.[ID] IS NULL
GROUP BY DownloadIssueSites.EDISID,
		 CASE WHEN OpenCalls.[ID] IS NULL THEN NULL ELSE dbo.GetCallReference(OpenCalls.[ID]) END 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorDownloadIssues] TO PUBLIC
    AS [dbo];

