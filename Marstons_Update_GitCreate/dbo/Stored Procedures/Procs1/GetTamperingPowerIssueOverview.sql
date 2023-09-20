CREATE PROCEDURE dbo.GetTamperingPowerIssueOverview 
(
     	@From		DATETIME,
     	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(Customer VARCHAR(50) NOT NULL, EDISID INT NOT NULL, SiteID VARCHAR(25) NOT NULL, [Name] VARCHAR(50) NOT NULL, LastDownload DATETIME NULL)
DECLARE @OpenTamperCases TABLE(EDISID INT NOT NULL, CaseID INT NOT NULL, StateID INT NOT NULL)
DECLARE @COTs TABLE(EDISID INT NOT NULL, ChangeDate DATETIME NOT NULL)
DECLARE @RefitCalls TABLE(EDISID INT NOT NULL, RaisedOn DATETIME NOT NULL, ClosedOn DATETIME NOT NULL)
DECLARE @SNACalls TABLE(EDISID INT NOT NULL, ClosedOn DATETIME NOT NULL, FaultType VARCHAR(50) NOT NULL)
DECLARE @LastSNACalls TABLE(EDISID INT NOT NULL, FaultType VARCHAR(50) NOT NULL)
DECLARE @LastMainsFail TABLE(EDISID INT NOT NULL, FaultDate DATETIME NOT NULL)

DECLARE @Customer VARCHAR(50)

SELECT @Customer = PropertyValue
FROM Configuration
WHERE PropertyName = 'Company Name'

INSERT INTO @Sites
SELECT @Customer, EDISID, SiteID, [Name], LastDownload
FROM Sites
WHERE Hidden = 0
AND SiteClosed = 0

INSERT INTO @OpenTamperCases
SELECT TamperCases.EDISID, TamperCases.CaseID, MAX(StateID) 
FROM TamperCases
JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
--WHERE EventDate <= @To
GROUP BY TamperCases.EDISID, TamperCases.CaseID
HAVING MAX(StateID) NOT IN (3, 6)
ORDER BY TamperCases.EDISID

INSERT INTO @COTs
SELECT EDISID, MAX([Date]) 
FROM SiteComments
WHERE HeadingType = 3004
AND [Date] <= @To
GROUP BY EDISID

INSERT INTO @RefitCalls
SELECT EDISID, RaisedOn, ClosedOn
FROM Calls
JOIN CallWorkItems ON CallWorkItems.CallID = Calls.[ID]
WHERE (CallWorkItems.WorkItemID = 6)
AND ClosedOn IS NOT NULL
ORDER BY ClosedOn DESC

INSERT INTO @SNACalls
SELECT EDISID, 
       ClosedOn,
       CASE CallFaults.FaultTypeID WHEN 2 THEN 'System not answering'
				WHEN 16 THEN 'System not downloading'
				WHEN 41 THEN 'BQM - BOX - Unable to Connect'
				WHEN 74 THEN 'System disabled PR'
       END
FROM Calls
JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
WHERE CallFaults.FaultTypeID IN (2, 16, 41, 74)
AND ClosedOn BETWEEN @From AND @To
AND ClosedOn IS NOT NULL
ORDER BY ClosedOn DESC

INSERT INTO @LastSNACalls
SELECT SNACalls.EDISID, SNACalls.FaultType
FROM @SNACalls AS SNACalls
JOIN
(SELECT EDISID, MAX(ClosedOn) AS ClosedOn
FROM @SNACalls
GROUP BY EDISID) AS TopSNACalls
ON SNACalls.EDISID = TopSNACalls.EDISID AND SNACalls.ClosedOn = TopSNACalls.ClosedOn

INSERT INTO @LastMainsFail
SELECT MasterDates.EDISID,
              MAX(CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, FaultStack.[Time]), DATEADD(mi, DATEPART(mi, FaultStack.[Time]), DATEADD(hh, DATEPART(hh, FaultStack.[Time]), MasterDates.[Date]))), 20))
FROM FaultStack
JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID
WHERE FaultStack.[Description] = 'Mains power failed'
GROUP BY MasterDates.EDISID

SELECT Sites.Customer,
	 Sites.SiteID,
	 Sites.[Name],
	 CASE WHEN OpenTamperCases.CaseID IS NULL THEN 'No' ELSE 'Yes' END AS OnTamperTracker,
	 Sites.LastDownload,
	 MAX(SNACalls.ClosedOn) AS LastSNA,
	 MAX(LastSNACalls.FaultType) AS LastSNACallType,
	 SUM(CASE WHEN SNACalls.ClosedOn >= COTs.ChangeDate THEN 1 ELSE 0 END) AS SNACallsAfterCOT,
	 MAX(RefitCalls.RaisedOn) AS LastRefitRaised,
	 MAX(RefitCalls.ClosedOn) AS LastRefitVisited,
	 LastMainsFail.FaultDate AS LastMainsFail
FROM @Sites AS Sites
LEFT JOIN @OpenTamperCases AS OpenTamperCases ON OpenTamperCases.EDISID = Sites.EDISID
LEFT JOIN @RefitCalls AS RefitCalls ON RefitCalls.EDISID = Sites.EDISID
JOIN @SNACalls AS SNACalls ON SNACalls.EDISID = Sites.EDISID
LEFT JOIN @LastSNACalls AS LastSNACalls ON LastSNACalls.EDISID = Sites.EDISID
LEFT JOIN @COTs AS COTs ON COTs.EDISID = Sites.EDISID
LEFT JOIN @LastMainsFail AS LastMainsFail ON LastMainsFail.EDISID = Sites.EDISID
GROUP BY Sites.Customer, 
	Sites.SiteID,
	Sites.[Name],
	CASE WHEN OpenTamperCases.CaseID IS NULL THEN 'No' ELSE 'Yes' END,
	Sites.LastDownload,
	LastMainsFail.FaultDate




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTamperingPowerIssueOverview] TO PUBLIC
    AS [dbo];

