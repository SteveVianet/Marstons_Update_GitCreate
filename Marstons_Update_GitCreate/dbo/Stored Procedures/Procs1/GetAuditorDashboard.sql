CREATE PROCEDURE dbo.GetAuditorDashboard
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON

DECLARE @CustomerID INT
DECLARE @LiveSites FLOAT
DECLARE @QualityAudits FLOAT
DECLARE @DMSAudits FLOAT
DECLARE @NewInstalls INT
DECLARE @FontSetupsToComplete INT
DECLARE @DownloadIssues INT
DECLARE @DataIssuesCount INT
DECLARE @PowerOffs INT
DECLARE @EquipmentAlertsCount INT
DECLARE @OverdueCallCount INT

DECLARE @RelevantSites TABLE(EDISID INT NOT NULL, Hidden BIT NOT NULL, LastDownload DATETIME NOT NULL)
DECLARE @DataIssues TABLE(EDISID INT NOT NULL, InputID INT NULL)
DECLARE @OverdueCalls TABLE(EDISID INT NOT NULL, CallID INT NOT NULL)
CREATE TABLE #EquipmentAlerts ([ID] INT NOT NULL, EDISID INT NOT NULL, AlertType VARCHAR(25) NOT NULL, AlertDate DATETIME NOT NULL)

SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @RelevantSites
(EDISID, Hidden, LastDownload)
SELECT EDISID, Hidden, ISNULL(LastDownload, 0)
FROM Sites
WHERE Quality = 1

SELECT @LiveSites = COUNT(*)
FROM @RelevantSites
WHERE Hidden = 0

-- Download Issues count. Sites which haven't downloaded for 24 hours.
SELECT @DownloadIssues = COUNT(*)
FROM @RelevantSites
WHERE LastDownload < DATEADD(day, -1, GETDATE())
AND Hidden = 0

-- Audits count. For Auditor (DMS) and Lite (Quality).
SELECT @QualityAudits = COUNT(DISTINCT CASE WHEN AuditType = 10 THEN EDISID END),
	   @DMSAudits = COUNT(DISTINCT CASE WHEN AuditType = 1 THEN EDISID END)
FROM SiteAudits
WHERE EDISID IN (SELECT EDISID FROM @RelevantSites)
AND [TimeStamp] BETWEEN @From AND @To

-- New Installs and Font Setups to Complete count.
SELECT @NewInstalls = SUM(CASE WHEN Sites.Hidden = 1 THEN 1 ELSE 0 END),
       @FontSetupsToComplete = SUM(CASE WHEN Sites.Hidden = 0 THEN 1 ELSE 0 END)
FROM ProposedFontSetups
JOIN @RelevantSites AS Sites ON Sites.EDISID = ProposedFontSetups.EDISID
LEFT JOIN dbo.Calls ON Calls.[ID] = ProposedFontSetups.CallID
WHERE ProposedFontSetups.Available = 1
AND ProposedFontSetups.Completed = 0
AND Calls.AbortReasonID = 0
AND Calls.CallTypeID = 2

-- Data Issues: Equipment (Ambient & Recircs)
INSERT INTO @DataIssues
(EDISID, InputID)
SELECT Sites.EDISID, EquipmentReadings.InputID
FROM (SELECT * FROM EquipmentReadings WHERE LogDate BETWEEN @From AND @To) AS EquipmentReadings
JOIN (SELECT * FROM Sites WHERE Quality = 1) AS Sites ON Sites.EDISID = EquipmentReadings.EDISID
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentReadings.EquipmentTypeID
--WHERE LogDate BETWEEN @From AND @To
WHERE (Value > 40 OR Value < 5)
AND EquipmentTypes.EquipmentSubTypeID IN (1, 2)
GROUP BY Sites.EDISID, InputID

-- Data Issues: Meters
INSERT INTO @DataIssues
(EDISID, InputID)
SELECT DISTINCT Sites.EDISID, Pump
FROM (SELECT * FROM DispenseActions WHERE StartTime BETWEEN @From AND @To) AS DispenseActions
JOIN @RelevantSites AS Sites ON Sites.EDISID = DispenseActions.EDISID
--WHERE StartTime BETWEEN @From AND @To
WHERE AverageTemperature > 25

-- Data Issues: Total count.
SELECT @DataIssuesCount = COUNT(*)
FROM @DataIssues

-- Power Offs count.
SELECT @PowerOffs = COUNT(*)
FROM FaultStack
JOIN MasterDates ON MasterDates.[ID] = FaultStack.FaultID
WHERE [Date] BETWEEN @From AND @To
AND [Description] = 'Mains power turned off'

-- Equipment Alarms count.
INSERT INTO #EquipmentAlerts
(ID, EDISID, AlertType, AlertDate)
EXEC [SQL1\SQL1].ServiceLogger.dbo.GetOutstandingCustomerEquipmentAlerts @CustomerID

SELECT @EquipmentAlertsCount = COUNT(*)
FROM #EquipmentAlerts

DROP TABLE #EquipmentAlerts

-- Overdue Service Calls. Open, Not On-Hold. 7 Days
INSERT INTO @OverdueCalls
(EDISID, CallID)
SELECT Sites.EDISID, Calls.[ID] --, MAX(CallStatusHistory.StatusID)
FROM Calls
JOIN @RelevantSites AS Sites ON Sites.EDISID = Calls.EDISID
JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID] AND CallStatusHistory.StatusID <> 6
WHERE RaisedOn < DATEADD(day, -7, GETDATE())
GROUP BY Sites.EDISID, Calls.[ID]
HAVING MAX(CallStatusHistory.StatusID) NOT IN (2, 4)

SELECT @OverdueCallCount = COUNT(*)
FROM @OverdueCalls

SELECT PropertyValue AS Customer,
	   ISNULL(@LiveSites, 0) AS LiveSites,
       ISNULL(@QualityAudits, 0) AS QualityAudits, 
       CASE WHEN ISNULL(@LiveSites, 0) = 0 THEN 0 ELSE @QualityAudits / @LiveSites * 100 END AS QualityPercent,
       ISNULL(@DMSAudits, 0) AS DMSAudits ,
       CASE WHEN ISNULL(@LiveSites, 0) = 0 THEN 0 ELSE @DMSAudits / @LiveSites * 100 END AS DMSPercent,
       ISNULL(@NewInstalls, 0) AS NewInstalls,
	   ISNULL(@FontSetupsToComplete, 0) AS FontSetupsToComplete,
	   ISNULL(@DownloadIssues, 0) AS DownloadIssues,
	   ISNULL(@DataIssuesCount, 0) AS DataIssues,
	   ISNULL(@PowerOffs, 0) AS PowerOffs,
	   ISNULL(@EquipmentAlertsCount, 0) AS EquipmentAlerts,
	   ISNULL(@OverdueCallCount, 0) AS OverdueCalls
FROM Configuration
WHERE PropertyName = 'Company Name'

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorDashboard] TO PUBLIC
    AS [dbo];

