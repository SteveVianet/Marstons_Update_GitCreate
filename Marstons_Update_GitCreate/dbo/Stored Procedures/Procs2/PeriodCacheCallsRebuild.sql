CREATE PROCEDURE [dbo].[PeriodCacheCallsRebuild]
(
	@AddToEstateTotals	BIT = 0
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @StartOfYear DATETIME
DECLARE @StartOfMonth DATETIME
DECLARE @Today DATETIME
DECLARE @StartOfPreviousPeriod DATETIME
DECLARE @EndOfPreviousPeriod DATETIME
DECLARE @StartOfPrevious6MonthPeriod DATETIME
DECLARE @EndOfPrevious6MonthPeriod DATETIME

DECLARE	@DatabaseID INT
DECLARE	@CustomerName VARCHAR(50)
DECLARE	@DMSSites INT
DECLARE	@IDraughtSites INT
DECLARE	@DMSCompletedCalls INT
DECLARE	@IDraughtCompletedCalls INT
DECLARE	@DMSCompletedCallsInSLA INT
DECLARE	@IDraughtCompletedCallsInSLA INT
DECLARE	@DMSCompletedCallsOutSLA INT
DECLARE	@IDraughtCompletedCallsOutSLA INT
DECLARE	@SNACallsTotal INT
DECLARE	@SNACallsInSLA INT
DECLARE	@SNACallsOutSLA INT
DECLARE	@CallsOutstanding INT
DECLARE	@CallsOpen INT
DECLARE @CallsCompleted INT
DECLARE @CallsCancelled INT
DECLARE @CallsAborted INT
DECLARE @CallsRaised INT
DECLARE	@AvgDaysFaultToApproved FLOAT
DECLARE	@AvgDaysApprovedToCompleted FLOAT
DECLARE	@SitesWithZeroCalls INT
DECLARE	@SitesWithOver5Calls INT
DECLARE	@CallsOnHold INT
DECLARE	@DMSCallsOnHold INT
DECLARE	@IDraughtCallsOnHold INT
DECLARE	@CallsOnHoldBrulinesIssue INT
DECLARE	@CallsOnHoldClientIssue INT
DECLARE	@FlowmetersInstalled INT
DECLARE	@DMSFlowmetersInstalledTotal INT
DECLARE	@IDraughtFlowmetersInstalledTotal INT
DECLARE	@DMSFlowmetersInstalledInPeriod INT
DECLARE	@IDraughtFlowmetersInstalledInPeriod INT
DECLARE	@FlowmetersCleaned INT
DECLARE @CalibrationFailureNoProduct INT
DECLARE @CalibrationFailureFobbing INT
DECLARE @CalibrationFailureDispenseIssue INT
DECLARE @AvgDMSDaysApprovedToCompleted INT
DECLARE @AvgIDraughtDaysApprovedToCompleted INT
DECLARE @CallsCompletedPrevious6Periods INT
DECLARE @AvgDMSDaysApprovedToCompletedPrevious6Periods INT
DECLARE @AvgIDraughtDaysApprovedToCompletedPrevious6Periods INT
DECLARE @CallsInProgress INT
DECLARE @CallsInProgressDays FLOAT
DECLARE @CallsOpenDays FLOAT
DECLARE @CallsOpenDaysDMS FLOAT
DECLARE @CallsOpenDaysIDraught FLOAT
DECLARE @CallsOpenOutsideSLA INT
DECLARE	@CallsOpenOutsideSLADMS INT
DECLARE @CallsOpenOutsideSLAIDraught INT
DECLARE @CallsOpenDaysOutsideSLA FLOAT
DECLARE @CallsOpenDaysOutsideSLADMS FLOAT
DECLARE @CallsOpenDaysOutsideSLAIDraught FLOAT
DECLARE	@DMSSitesWithZeroCalls INT
DECLARE	@DMSSitesWithOver5Calls INT
DECLARE	@IDraughtSitesWithZeroCalls INT
DECLARE	@IDraughtSitesWithOver5Calls INT
DECLARE @DMSCallsCompletedPrevious6Periods INT
DECLARE @IDraughtCallsCompletedPrevious6Periods INT
DECLARE @SNACallsDMSTotal INT
DECLARE @SNACallsDMSInSLA INT
DECLARE @SNACallsDMSOutSLA INT
DECLARE @SNACallsIDraughtTotal INT
DECLARE @SNACallsIDraughtInSLA INT
DECLARE @SNACallsIDraughtOutSLA INT
DECLARE @CallsRaisedDMS INT
DECLARE @CallsRaisedIDraught INT
DECLARE @CallsOutstandingDMS INT
DECLARE @CallsOutstandingIDraught INT
DECLARE @CallsOpenDMS INT
DECLARE @CallsOpenIDraught INT
DECLARE @CallsInProgressDMS INT
DECLARE @CallsInProgressIDraught INT
DECLARE @CallsInProgressAvgDaysDMS FLOAT
DECLARE @CallsInProgressAvgDaysIDraught FLOAT
DECLARE @DMSCallsOnHoldBrulinesIssue INT
DECLARE @IDraughtCallsOnHoldBrulinesIssue INT
DECLARE @DMSCallsOnHoldClientIssue INT
DECLARE @IDraughtCallsOnHoldClientIssue INT
DECLARE @FlowmetersCleanedDMS INT
DECLARE @FlowmetersCleanedIDraught INT
DECLARE @CallsCancelledDMS INT
DECLARE @CallsCancelledIDraught INT
DECLARE @CallsAbortedDMS INT
DECLARE @CallsAbortedIDraught INT
DECLARE @CalibrationFailureNoProductDMS INT
DECLARE @CalibrationFailureNoProductIDraught INT
DECLARE @CalibrationFailureFobbingDMS INT
DECLARE @CalibrationFailureFobbingIDraught INT
DECLARE @CalibrationFailureDispenseIssueDMS INT
DECLARE @CalibrationFailureDispenseIssueIDraught INT
DECLARE @DMSSitesAllInclusive INT
DECLARE @IDraughtSitesAllInclusive INT
DECLARE @DMSSitesPAYGOther INT
DECLARE @IDraughtSitesPAYGOther INT
DECLARE @DMSSitesOver5Years INT
DECLARE @IDraughtSitesOver5Years INT
DECLARE @DMSSitesUnder5Years INT
DECLARE @IDraughtSitesUnder5Years INT

DECLARE @PriorityCallsOpenDMS INT
DECLARE @PriorityCallsRaisedDMS INT
DECLARE @PriorityCallsOutstandingDMS INT
DECLARE @PriorityCallsInProgressDMS INT
DECLARE @PriorityCallsInProgressAvgDaysDMS FLOAT
DECLARE @PriorityCallsOpenOutsideSLADMS INT
DECLARE @PriorityCallsOpenAvgDaysDMS FLOAT
DECLARE @PriorityCallsOpenOutsideSLADMSAvgDays FLOAT

DECLARE @PriorityCallsOpenIDraught INT
DECLARE @PriorityCallsRaisedIDraught INT
DECLARE @PriorityCallsOutstandingIDraught INT
DECLARE @PriorityCallsInProgressIDraught INT
DECLARE @PriorityCallsInProgressAvgDaysIDraught FLOAT
DECLARE @PriorityCallsOpenOutsideSLAIDraught INT
DECLARE @PriorityCallsOpenAvgDaysIDraught FLOAT
DECLARE @PriorityCallsOpenOutsideSLAIDraughtAvgDays FLOAT

CREATE TABLE #Periods(Period INT,
					  FinancialYear VARCHAR(20),
					  StartDate DATETIME,
					  EndDate DATETIME)

CREATE TABLE #CallFaultTypes([ID] INT NOT NULL, 
							[Description] VARCHAR(255) NOT NULL, 
							RequiresAdditionalInfo BIT NOT NULL, 
							MaxOccurences INT NOT NULL, 
							PreventsDownload BIT NOT NULL, 
							ForceRequirePO BIT NOT NULL, 
							ForceNotRequirePO BIT NOT NULL, 
							DefaultEngineer INT NULL, 
							AdditionalInfoType INT NOT NULL, 
							DisplayColour INT NOT NULL, 
							WorkDetailDescription VARCHAR(8000) NULL, 
							Depreciated BIT NOT NULL, 
							CallType INT NOT NULL, 
							SLA INT NOT NULL,
							Category VARCHAR(50) NULL,
							ExcludeFromReporting BIT NOT NULL)

CREATE TABLE #CallSubStatuses([ID] INT, ParentStatusID INT, [Description] VARCHAR(255), BrulinesIssue BIT, Deprecated BIT)
DECLARE @Calls TABLE([ID] INT NOT NULL, EDISID INT NOT NULL, StatusID INT NOT NULL, LatestStatusChangeDate DATETIME NOT NULL, Quality BIT NOT NULL, OnHoldBrulinesIssue BIT NULL, SLA INT NOT NULL, WeekdaysTaken INT, IsSNACall BIT, AbortReasonID INT, RaisedOn DATETIME, PriorityID INT, ClosedOn DATETIME, Over5Years BIT, AllInclusiveCall BIT)
DECLARE @SNACalls TABLE([ID] INT NOT NULL)

INSERT INTO #Periods
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetPeriods 1

SET @Today = GETDATE()

DECLARE @Date DATETIME
SET @Date = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @Today)))

--SET @StartOfYear =  CAST(CAST(CASE WHEN MONTH(@Today) < 4 THEN YEAR(DATEADD(year, -1, @Today)) ELSE YEAR(@Today) END AS VARCHAR(4)) + '/04/01' AS DATETIME)

SELECT @StartOfYear = StartDate
FROM #Periods
WHERE Period = 1

--SET @StartOfMonth =  CAST(CAST(YEAR(@Today) AS VARCHAR(4)) + '/' + 
--                CAST(MONTH(@Today) AS VARCHAR(2)) + '/01' AS DATETIME)

SELECT TOP 1 @StartOfPreviousPeriod = StartDate, @EndOfPreviousPeriod = EndDate
FROM #Periods
ORDER BY StartDate DESC

--SET @StartOfPreviousPeriod = DATEADD(MONTH, -1, @StartOfMonth)
--SET @EndOfPreviousPeriod = DATEADD(SECOND, -1, @StartOfMonth)

SET @EndOfPrevious6MonthPeriod = @EndOfPreviousPeriod

SELECT TOP 1 @StartOfPrevious6MonthPeriod = StartDate
FROM
(
	SELECT TOP 6 Period,
				 FinancialYear,
				 StartDate,
				 EndDate
	FROM #Periods
	ORDER BY StartDate DESC
) AS Last6Periods
ORDER BY StartDate ASC

--SET @StartOfPrevious6MonthPeriod = DATEADD(MONTH, -6, @StartOfPreviousPeriod)
--SET @EndOfPrevious6MonthPeriod = DATEADD(SECOND, -1, @StartOfPreviousPeriod)

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CustomerName = PropertyValue
FROM Configuration
WHERE PropertyName = 'Company Name'

INSERT INTO #CallSubStatuses
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallSubStatuses 2

INSERT INTO #CallFaultTypes
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallFaultTypes

INSERT INTO @SNACalls
([ID])
SELECT DISTINCT CallID
FROM CallFaults
JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
WHERE CallFaultTypes.[Category] = 'Comms'

SELECT @DMSSites = SUM(CASE WHEN Quality = 0 THEN 1 ELSE 0 END),
	   @IDraughtSites = SUM(CASE WHEN Quality = 1 THEN 1 ELSE 0 END),
	   @DMSSitesAllInclusive = SUM(CASE WHEN Quality = 0 AND AllInclusive = 1 THEN 1 ELSE 0 END),
	   @IDraughtSitesAllInclusive = SUM(CASE WHEN Quality = 1 AND AllInclusive = 1 THEN 1 ELSE 0 END),
	   @DMSSitesPAYGOther = SUM(CASE WHEN Quality = 0 AND AllInclusive = 0 THEN 1 ELSE 0 END),
	   @IDraughtSitesPAYGOther = SUM(CASE WHEN Quality = 1 AND AllInclusive = 0 THEN 1 ELSE 0 END),
	   @DMSSitesOver5Years = SUM(CASE WHEN Quality = 0 AND DATEDIFF(YEAR, InstallationDate, GETDATE()) >= 5 THEN 1 ELSE 0 END),
	   @IDraughtSitesOver5Years = SUM(CASE WHEN Quality = 1 AND DATEDIFF(YEAR, InstallationDate, GETDATE()) >= 5 THEN 1 ELSE 0 END),
	   @DMSSitesUnder5Years = SUM(CASE WHEN Quality = 0 AND DATEDIFF(YEAR, InstallationDate, GETDATE()) < 5 THEN 1 ELSE 0 END),
	   @IDraughtSitesUnder5Years = SUM(CASE WHEN Quality = 1 AND DATEDIFF(YEAR, InstallationDate, GETDATE()) < 5 THEN 1 ELSE 0 END)
FROM Sites
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
WHERE Hidden = 0

INSERT INTO @Calls
([ID], EDISID, StatusID,LatestStatusChangeDate, Quality, OnHoldBrulinesIssue, SLA, WeekdaysTaken, IsSNACall, AbortReasonID, RaisedOn, PriorityID, ClosedOn, Over5Years, AllInclusiveCall)
SELECT CallID,
	   EDISID,
	   MAX(StatusID),
	   LatestChangeDate,
	   Quality,
	   BrulinesIssue,
	   SLA,
	   CASE WHEN ClosedOn IS NULL THEN dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), GETDATE()) ELSE dbo.fnGetWeekdayCount(COALESCE(POConfirmed, RaisedOn), ClosedOn) END AS DaysTaken,
	   IsSNACall,
	   AbortReasonID,
	   RaisedOn,
	   PriorityID,
	   ClosedOn,
	   Over5Years,
	   AllInclusiveCall
FROM (
SELECT	CallStatusHistory.CallID, 
		Sites.EDISID, 
		StatusID, 
		LatestChangeDate, 
		Quality, 
		BrulinesIssue,
		MAX(CASE WHEN OverrideSLA > 0 THEN OverrideSLA
			 WHEN CallTypeID = 2 AND SalesReference LIKE 'TRA%'	THEN 21
		     WHEN CallTypeID = 2 AND SalesReference NOT LIKE 'TRA%'THEN 7
		     ELSE COALESCE(CallFaults.SLA, CallFaultTypes.SLA, 0) END) AS SLA,
		--CASE WHEN StatusID <> 4 THEN dbo.fnGetWeekdayCount(RaisedOn, GETDATE()) - DaysOnHold ELSE dbo.fnGetWeekdayCount(RaisedOn, LatestChangeDate) - DaysOnHold END AS DaysTaken,
		CASE WHEN SNACalls.[ID] IS NOT NULL THEN 1 ELSE 0 END AS IsSNACall,
		AbortReasonID,
		RaisedOn,
		POConfirmed,
		PriorityID,
		DaysOnHold,
		ClosedOn,
	    CASE WHEN DATEDIFF(YEAR, COALESCE(Calls.InstallationDate, Sites.InstallationDate), RaisedOn) > 5 THEN 1 ELSE 0 END AS Over5Years,
	    Contracts.AllInclusive AS AllInclusiveCall
FROM CallStatusHistory
JOIN
(
SELECT CallID, MAX(ChangedOn) AS LatestChangeDate
FROM CallStatusHistory
GROUP BY CallID
) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
AND LatestCallChanges.LatestChangeDate = CallStatusHistory.ChangedOn
JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
JOIN Sites ON Sites.EDISID = Calls.EDISID
JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
LEFT JOIN #CallSubStatuses AS CallSubStatuses ON CallSubStatuses.[ID] = CallStatusHistory.SubStatusID
LEFT JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
LEFT JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
LEFT JOIN @SNACalls AS SNACalls ON SNACalls.[ID] = Calls.[ID]
WHERE Calls.PlanningIssueID = 1
GROUP BY CallStatusHistory.CallID, Sites.EDISID, StatusID, LatestChangeDate, Quality, BrulinesIssue, CASE WHEN SNACalls.[ID] IS NOT NULL THEN 1 ELSE 0 END, AbortReasonID, RaisedOn, POConfirmed, PriorityID, DaysOnHold, ClosedOn, CASE WHEN DATEDIFF(YEAR, COALESCE(Calls.InstallationDate, Sites.InstallationDate), RaisedOn) > 5 THEN 1 ELSE 0 END, Contracts.AllInclusive
) AS AllCalls
GROUP BY CallID,
	   EDISID,
	   LatestChangeDate,
	   Quality,
	   BrulinesIssue,
	   SLA,
	   IsSNACall,
	   AbortReasonID,
	   RaisedOn,
	   POConfirmed,
	   PriorityID,
	   DaysOnHold,
	   ClosedOn,
	   Over5Years,
	   AllInclusiveCall

DELETE 
FROM @Calls 
WHERE [ID] IN
(
	SELECT Calls.[ID] 
	FROM @Calls AS Calls
	JOIN CallFaults ON CallFaults.CallID = Calls.[ID] 
	JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
	WHERE ExcludeFromReporting = 1
	--AND CallFaults.FaultTypeID IN (75, 76)
)

SELECT	@CallsOutstanding = SUM(CASE WHEN StatusID IN (1, 2, 3) AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@CallsOutstandingDMS = SUM(CASE WHEN StatusID IN (1, 2, 3) AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsOutstandingIDraught = SUM(CASE WHEN StatusID IN (1, 2, 3) AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsOpen = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@CallsOpenDMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 0 THEN 1 ELSE 0 END),
		@CallsOpenIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 1 THEN 1 ELSE 0 END),
		@CallsCompleted = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN 1 ELSE 0 END),
		@CallsCompletedPrevious6Periods = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPrevious6MonthPeriod AND @EndOfPrevious6MonthPeriod THEN 1 ELSE 0 END),
		@DMSCompletedCalls = SUM(CASE WHEN ClosedOn IS NOT NULL AND Quality = 0 AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN 1 ELSE 0 END),
		@IDraughtCompletedCalls = SUM(CASE WHEN ClosedOn IS NOT NULL AND Quality = 1 AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN 1 ELSE 0 END),
		@DMSCallsCompletedPrevious6Periods = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 0 AND LatestStatusChangeDate BETWEEN @StartOfPrevious6MonthPeriod AND @EndOfPrevious6MonthPeriod THEN 1 ELSE 0 END),
		@IDraughtCallsCompletedPrevious6Periods = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 1 AND LatestStatusChangeDate BETWEEN @StartOfPrevious6MonthPeriod AND @EndOfPrevious6MonthPeriod THEN 1 ELSE 0 END),
		@CallsOnHold = SUM(CASE WHEN StatusID = 2 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@DMSCallsOnHold = SUM(CASE WHEN StatusID = 2 AND Quality = 0 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@IDraughtCallsOnHold = SUM(CASE WHEN StatusID = 2 AND Quality = 1 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@CallsOnHoldBrulinesIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 1 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@DMSCallsOnHoldBrulinesIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 1 AND AbortReasonID = 0 AND Quality = 0 THEN 1 ELSE 0 END),
		@IDraughtCallsOnHoldBrulinesIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 1 AND AbortReasonID = 0 AND Quality = 1 THEN 1 ELSE 0 END),
		@CallsOnHoldClientIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 0 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@DMSCallsOnHoldClientIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 0 AND AbortReasonID = 0 AND Quality = 0 THEN 1 ELSE 0 END),
		@IDraughtCallsOnHoldClientIssue = SUM(CASE WHEN StatusID = 2 AND OnHoldBrulinesIssue = 0 AND AbortReasonID = 0 AND Quality = 1 THEN 1 ELSE 0 END),
		@DMSCompletedCallsInSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 0 AND SLA >= WeekdaysTaken THEN 1 ELSE 0 END),
		@IDraughtCompletedCallsInSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 1 AND SLA >= WeekdaysTaken THEN 1 ELSE 0 END),
		@DMSCompletedCallsOutSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 0 AND SLA < WeekdaysTaken THEN 1 ELSE 0 END),
		@IDraughtCompletedCallsOutSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 1 AND SLA < WeekdaysTaken THEN 1 ELSE 0 END),
		@AvgDaysApprovedToCompleted = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN WeekdaysTaken ELSE 0 END),
		@AvgDMSDaysApprovedToCompleted = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN WeekdaysTaken ELSE 0 END),
		@AvgDMSDaysApprovedToCompletedPrevious6Periods = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 0 AND LatestStatusChangeDate BETWEEN @StartOfPrevious6MonthPeriod AND @EndOfPrevious6MonthPeriod THEN WeekdaysTaken ELSE 0 END),
		@AvgIDraughtDaysApprovedToCompleted = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 1 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN WeekdaysTaken ELSE 0 END),
		@AvgIDraughtDaysApprovedToCompletedPrevious6Periods = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND Quality = 1 AND LatestStatusChangeDate BETWEEN @StartOfPrevious6MonthPeriod AND @EndOfPrevious6MonthPeriod THEN WeekdaysTaken ELSE 0 END),
		@SNACallsTotal = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3)THEN 1 ELSE 0 END),
		@SNACallsDMSTotal = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND Quality = 0 THEN 1 ELSE 0 END),
		@SNACallsIDraughtTotal = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND Quality = 1 THEN 1 ELSE 0 END),	
		@SNACallsInSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA >= WeekdaysTaken THEN 1 ELSE 0 END),
		@SNACallsDMSInSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA >= WeekdaysTaken AND Quality = 0 THEN 1 ELSE 0 END),
		@SNACallsIDraughtInSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA >= WeekdaysTaken AND Quality = 1 THEN 1 ELSE 0 END),	
		@SNACallsOutSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA < WeekdaysTaken THEN 1 ELSE 0 END),
		@SNACallsDMSOutSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA < WeekdaysTaken AND Quality = 0 THEN 1 ELSE 0 END),
		@SNACallsIDraughtOutSLA = SUM(CASE WHEN ClosedOn IS NOT NULL AND AbortReasonID = 0 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND PriorityID IN (2, 3) AND SLA < WeekdaysTaken AND Quality = 1 THEN 1 ELSE 0 END),
		@CallsCancelled = SUM(CASE WHEN AbortReasonID = 3 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN 1 ELSE 0 END),
		@CallsCancelledDMS = SUM(CASE WHEN AbortReasonID = 3 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 0 THEN 1 ELSE 0 END),
		@CallsCancelledIDraught = SUM(CASE WHEN AbortReasonID = 3 AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 1 THEN 1 ELSE 0 END),
		@CallsAborted = SUM(CASE WHEN AbortReasonID IN (1, 2, 4, 5) AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod THEN 1 ELSE 0 END),
		@CallsAbortedDMS = SUM(CASE WHEN AbortReasonID IN (1, 2, 4, 5) AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 0 THEN 1 ELSE 0 END),
		@CallsAbortedIDraught = SUM(CASE WHEN AbortReasonID IN (1, 2, 4, 5) AND LatestStatusChangeDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod AND Quality = 1 THEN 1 ELSE 0 END),
		@CallsRaised = SUM(CASE WHEN AbortReasonID = 0 AND StatusID = 6 THEN 1 ELSE 0 END),
		@CallsRaisedDMS = SUM(CASE WHEN AbortReasonID = 0 AND StatusID = 6 AND Quality = 0 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsRaisedIDraught = SUM(CASE WHEN AbortReasonID = 0 AND StatusID = 6 AND Quality = 1 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsInProgress = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 THEN 1 ELSE 0 END),
		@CallsInProgressDMS = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsInProgressIDraught = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsInProgressDays = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 THEN WeekdaysTaken ELSE 0 END),
		@CallsInProgressAvgDaysDMS = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (0, 1) THEN WeekdaysTaken ELSE 0 END),
		@CallsInProgressAvgDaysIDraught = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (0, 1) THEN WeekdaysTaken ELSE 0 END),
		@CallsOpenDays = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 THEN WeekdaysTaken ELSE 0 END),
		@CallsOpenDaysDMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (0, 1) THEN WeekdaysTaken ELSE 0 END),
		@CallsOpenDaysIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (0, 1) THEN WeekdaysTaken ELSE 0 END),
		@CallsOpenOutsideSLA = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken THEN 1 ELSE 0 END),
		@CallsOpenOutsideSLADMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 0 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsOpenOutsideSLAIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 1 AND PriorityID IN (0, 1) THEN 1 ELSE 0 END),
		@CallsOpenDaysOutsideSLA = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken THEN WeekdaysTaken - SLA ELSE 0 END),
		@CallsOpenDaysOutsideSLADMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 0 AND PriorityID IN (0, 1) THEN WeekdaysTaken - SLA ELSE 0 END),
		@CallsOpenDaysOutsideSLAIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 1 AND PriorityID IN (0, 1) THEN WeekdaysTaken - SLA ELSE 0 END),
		
		@PriorityCallsOpenDMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsRaisedDMS = SUM(CASE WHEN AbortReasonID = 0 AND StatusID = 6 AND Quality = 0 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsOutstandingDMS = SUM(CASE WHEN StatusID IN (1, 2, 3) AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsInProgressDMS = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsInProgressAvgDaysDMS = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (2, 3) THEN WeekdaysTaken ELSE 0 END),
		@PriorityCallsOpenOutsideSLADMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 0 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsOpenAvgDaysDMS = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 0 AND PriorityID IN (2, 3) THEN WeekdaysTaken ELSE 0 END),
		@PriorityCallsOpenOutsideSLADMSAvgDays = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 0 AND PriorityID IN (2, 3) THEN WeekdaysTaken - SLA ELSE 0 END),

		@PriorityCallsOpenIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsRaisedIDraught = SUM(CASE WHEN AbortReasonID = 0 AND StatusID = 6 AND Quality = 1 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsOutstandingIDraught = SUM(CASE WHEN StatusID IN (1, 2, 3) AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsInProgressIDraught = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsInProgressAvgDaysIDraught = SUM(CASE WHEN StatusID = 3 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (2, 3) THEN WeekdaysTaken ELSE 0 END),
		@PriorityCallsOpenOutsideSLAIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 1 AND PriorityID IN (2, 3) THEN 1 ELSE 0 END),
		@PriorityCallsOpenAvgDaysIDraught = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND Quality = 1 AND PriorityID IN (2, 3) THEN WeekdaysTaken ELSE 0 END),
		@PriorityCallsOpenOutsideSLAIDraughtAvgDays = SUM(CASE WHEN StatusID = 1 AND AbortReasonID = 0 AND SLA < WeekdaysTaken AND Quality = 1 AND PriorityID IN (2, 3) THEN WeekdaysTaken - SLA ELSE 0 END)

FROM @Calls AS Calls

SELECT	@SitesWithZeroCalls = SUM(CASE WHEN CallCount = 0 THEN 1 ELSE 0 END),
		@SitesWithOver5Calls = SUM(CASE WHEN CallCount > 5 THEN 1 ELSE 0 END),
		@DMSSitesWithZeroCalls = SUM(CASE WHEN CallCount = 0 AND Quality = 0 THEN 1 ELSE 0 END),
		@DMSSitesWithOver5Calls = SUM(CASE WHEN CallCount > 5 AND Quality = 0 THEN 1 ELSE 0 END),
		@IDraughtSitesWithZeroCalls = SUM(CASE WHEN CallCount = 0 AND Quality = 1 THEN 1 ELSE 0 END),
		@IDraughtSitesWithOver5Calls = SUM(CASE WHEN CallCount > 5 AND Quality = 1 THEN 1 ELSE 0 END)
FROM
(
SELECT Sites.EDISID, Quality, COUNT(*) AS CallCount
FROM Sites
LEFT JOIN Calls ON Calls.EDISID = Sites.EDISID AND Calls.RaisedOn BETWEEN @StartOfYear AND @Today AND AbortReasonID = 0
WHERE Hidden = 0
GROUP BY Sites.EDISID, Quality
) AS SiteCallCount

SELECT @FlowmetersInstalled = COUNT(*),
	   @DMSFlowmetersInstalledTotal = SUM(CASE WHEN Quality = 0 THEN 1 ELSE 0 END),
	   @IDraughtFlowmetersInstalledTotal = SUM(CASE WHEN Quality = 1 THEN 1 ELSE 0 END)
FROM PumpSetup
JOIN Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE ValidTo IS NULL
AND Hidden = 0

SELECT	@DMSFlowmetersInstalledInPeriod = SUM(CASE WHEN JobType = 1 AND Quality = 0 THEN 1 ELSE 0 END),
		@IDraughtFlowmetersInstalledInPeriod = SUM(CASE WHEN JobType = 1 AND Quality = 1 THEN 1 ELSE 0 END),
		@FlowmetersCleaned = SUM(CASE WHEN JobType = 2 AND CalibrationIssueType = 4 THEN 1 ELSE 0 END),
		@FlowmetersCleanedDMS = SUM(CASE WHEN JobType = 2 AND CalibrationIssueType = 4 AND Quality = 0 THEN 1 ELSE 0 END),
		@FlowmetersCleanedIDraught = SUM(CASE WHEN JobType = 2 AND CalibrationIssueType = 4 AND Quality = 1 THEN 1 ELSE 0 END),
		@CalibrationFailureNoProduct = SUM(CASE WHEN CalibrationIssueType = 7 THEN 1 ELSE 0 END),
		@CalibrationFailureNoProductDMS = SUM(CASE WHEN CalibrationIssueType = 7 AND Quality = 0 THEN 1 ELSE 0 END),
		@CalibrationFailureNoProductIDraught = SUM(CASE WHEN CalibrationIssueType = 7 AND Quality = 1 THEN 1 ELSE 0 END),
		@CalibrationFailureFobbing = SUM(CASE WHEN CalibrationIssueType = 9 THEN 1 ELSE 0 END),
		@CalibrationFailureFobbingDMS = SUM(CASE WHEN CalibrationIssueType = 9 AND Quality = 0 THEN 1 ELSE 0 END),
		@CalibrationFailureFobbingIDraught = SUM(CASE WHEN CalibrationIssueType = 9 AND Quality = 1 THEN 1 ELSE 0 END),
		@CalibrationFailureDispenseIssue = SUM(CASE WHEN CalibrationIssueType IN (2, 3, 4, 5, 6) THEN 1 ELSE 0 END),
		@CalibrationFailureDispenseIssueDMS = SUM(CASE WHEN CalibrationIssueType IN (2, 3, 4, 5, 6) AND Quality = 0 THEN 1 ELSE 0 END),
		@CalibrationFailureDispenseIssueIDraught = SUM(CASE WHEN CalibrationIssueType IN (2, 3, 4, 5, 6) AND Quality = 1 THEN 1 ELSE 0 END)
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.[ID] = ProposedFontSetupItems.ProposedFontSetupID
JOIN Sites ON Sites.EDISID = ProposedFontSetups.EDISID
WHERE ProposedFontSetups.CreateDate BETWEEN @StartOfPreviousPeriod AND @EndOfPreviousPeriod
AND Completed = 1

DECLARE @TotalCallsOpenDays INT
DECLARE @TotalCallsInProgressDays INT
DECLARE @TotalCallsInProgressDaysDMS INT
DECLARE @TotalCallsInProgressDaysIDraught INT
DECLARE @TotalCallsOpenDaysOutsideSLA INT
DECLARE @TotalCallsOpenDaysOutsideSLADMS INT
DECLARE @TotalCallsOpenDaysOutsideSLAIDraught INT
DECLARE @TotalDaysApprovedToCompleted INT
DECLARE @TotalDMSDaysApprovedToCompleted  INT
DECLARE @TotalIDraughtDaysApprovedToCompleted INT
DECLARE @TotalDMSDaysApprovedToCompletedPrevious6Periods INT
DECLARE @TotalIDraughtDaysApprovedToCompletedPrevious6Periods INT

DECLARE @TotalPriorityCallsInProgressAvgDaysDMS INT
DECLARE @TotalPriorityCallsOpenAvgDaysDMS INT
DECLARE @TotalPriorityCallsOpenOutsideSLADMSAvgDays INT
DECLARE @TotalPriorityCallsInProgressAvgDaysIDraught INT
DECLARE @TotalPriorityCallsOpenAvgDaysIDraught INT
DECLARE @TotalPriorityCallsOpenOutsideSLAIDraughtAvgDays INT

SET @TotalCallsOpenDays = @CallsOpenDays
SET @TotalCallsInProgressDays = @CallsInProgressDays
SET @TotalCallsInProgressDaysDMS = @CallsInProgressAvgDaysDMS
SET @TotalCallsInProgressDaysIDraught = @CallsInProgressAvgDaysIDraught
SET @TotalCallsOpenDaysOutsideSLA = @CallsOpenDaysOutsideSLA
SET @TotalCallsOpenDaysOutsideSLADMS = @CallsOpenDaysOutsideSLADMS
SET @TotalCallsOpenDaysOutsideSLAIDraught = @CallsOpenDaysOutsideSLAIDraught
SET @TotalPriorityCallsInProgressAvgDaysDMS = @PriorityCallsInProgressAvgDaysDMS
SET @TotalPriorityCallsOpenAvgDaysDMS = @PriorityCallsOpenAvgDaysDMS
SET @TotalPriorityCallsOpenOutsideSLADMSAvgDays = @PriorityCallsOpenOutsideSLADMSAvgDays
SET @TotalPriorityCallsInProgressAvgDaysIDraught = @PriorityCallsInProgressAvgDaysIDraught
SET @TotalPriorityCallsOpenAvgDaysIDraught = @PriorityCallsOpenAvgDaysIDraught
SET @TotalPriorityCallsOpenOutsideSLAIDraughtAvgDays = @PriorityCallsOpenOutsideSLAIDraughtAvgDays

SET @TotalDaysApprovedToCompleted = @AvgDaysApprovedToCompleted
SET @TotalDMSDaysApprovedToCompleted = @AvgDMSDaysApprovedToCompleted
SET @TotalIDraughtDaysApprovedToCompleted = @AvgIDraughtDaysApprovedToCompleted
SET @TotalDMSDaysApprovedToCompletedPrevious6Periods = @AvgDMSDaysApprovedToCompletedPrevious6Periods
SET @TotalIDraughtDaysApprovedToCompletedPrevious6Periods = @AvgIDraughtDaysApprovedToCompletedPrevious6Periods

SET @CallsOpenDays = CASE WHEN @CallsOpen = 0 THEN 0 ELSE @CallsOpenDays / @CallsOpen END
SET @CallsOpenDaysDMS = CASE WHEN @CallsOpenDMS = 0 THEN 0 ELSE @CallsOpenDaysDMS / @CallsOpenDMS END
SET @CallsOpenDaysIDraught = CASE WHEN @CallsOpenIDraught = 0 THEN 0 ELSE @CallsOpenDaysIDraught / @CallsOpenIDraught END
SET @CallsInProgressDays = CASE WHEN @CallsInProgress = 0 THEN 0 ELSE @CallsInProgressDays / @CallsInProgress END
SET @CallsInProgressAvgDaysDMS = CASE WHEN @CallsInProgressDMS = 0 THEN 0 ELSE @CallsInProgressAvgDaysDMS / @CallsInProgressDMS END
SET @CallsInProgressAvgDaysIDraught = CASE WHEN @CallsInProgressIDraught = 0 THEN 0 ELSE @CallsInProgressAvgDaysIDraught / @CallsInProgressIDraught END
SET @CallsOpenDaysOutsideSLA = CASE WHEN @CallsOpenOutsideSLA = 0 THEN 0 ELSE @CallsOpenDaysOutsideSLA / @CallsOpenOutsideSLA END
SET @CallsOpenDaysOutsideSLADMS = CASE WHEN @CallsOpenOutsideSLADMS = 0 THEN 0 ELSE @CallsOpenDaysOutsideSLADMS / @CallsOpenOutsideSLADMS END
SET @CallsOpenDaysOutsideSLAIDraught = CASE WHEN @CallsOpenOutsideSLAIDraught = 0 THEN 0 ELSE @CallsOpenDaysOutsideSLAIDraught / @CallsOpenOutsideSLAIDraught END
SET @PriorityCallsInProgressAvgDaysDMS = CASE WHEN @PriorityCallsInProgressDMS = 0 THEN 0 ELSE @PriorityCallsInProgressAvgDaysDMS / @PriorityCallsInProgressDMS END
SET @PriorityCallsOpenAvgDaysDMS = CASE WHEN @PriorityCallsOpenDMS = 0 THEN 0 ELSE @PriorityCallsOpenAvgDaysDMS / @PriorityCallsOpenDMS END
SET @PriorityCallsOpenOutsideSLADMSAvgDays = CASE WHEN @PriorityCallsOpenOutsideSLADMS= 0 THEN 0 ELSE @PriorityCallsOpenOutsideSLADMSAvgDays / @PriorityCallsOpenOutsideSLADMS END
SET @PriorityCallsInProgressAvgDaysIDraught = CASE WHEN @PriorityCallsInProgressIDraught = 0 THEN 0 ELSE @PriorityCallsInProgressAvgDaysIDraught / @PriorityCallsInProgressIDraught END
SET @PriorityCallsOpenAvgDaysIDraught = CASE WHEN @PriorityCallsOpenIDraught = 0 THEN 0 ELSE @PriorityCallsOpenAvgDaysIDraught / @PriorityCallsOpenIDraught END
SET @PriorityCallsOpenOutsideSLAIDraughtAvgDays = CASE WHEN @PriorityCallsOpenOutsideSLAIDraught= 0 THEN 0 ELSE @PriorityCallsOpenOutsideSLAIDraughtAvgDays / @PriorityCallsOpenOutsideSLAIDraught END

SET @AvgDaysApprovedToCompleted = CASE WHEN @CallsCompleted = 0 THEN 0 ELSE @AvgDaysApprovedToCompleted / @CallsCompleted END
SET @AvgDMSDaysApprovedToCompleted = CASE WHEN @DMSCompletedCalls = 0 THEN 0 ELSE @AvgDMSDaysApprovedToCompleted / @DMSCompletedCalls END
SET @AvgIDraughtDaysApprovedToCompleted = CASE WHEN @IDraughtCompletedCalls = 0 THEN 0 ELSE @AvgIDraughtDaysApprovedToCompleted / @IDraughtCompletedCalls END
SET @AvgDMSDaysApprovedToCompletedPrevious6Periods = CASE WHEN @DMSCallsCompletedPrevious6Periods = 0 THEN 0 ELSE @AvgDMSDaysApprovedToCompletedPrevious6Periods / @DMSCallsCompletedPrevious6Periods END
SET @AvgIDraughtDaysApprovedToCompletedPrevious6Periods = CASE WHEN @IDraughtCallsCompletedPrevious6Periods = 0 THEN 0 ELSE @AvgIDraughtDaysApprovedToCompletedPrevious6Periods / @IDraughtCallsCompletedPrevious6Periods END

DROP TABLE #CallSubStatuses
DROP TABLE #CallFaultTypes
DROP TABLE #Periods

DELETE FROM PeriodCacheCalls WHERE [Date] = @Date

INSERT INTO PeriodCacheCalls
(	DatabaseID,
	CustomerName,
	[Date],
	DMSSites,
	IDraughtSites,
	DMSCompletedCalls,
	IDraughtCompletedCalls,
	CallsCompleted,
	DMSCompletedCallsInSLA,
	IDraughtCompletedCallsInSLA,
	DMSCompletedCallsOutSLA,
	IDraughtCompletedCallsOutSLA,
	SNACallsTotal,
	SNACallsInSLA,
	SNACallsOutSLA,
	CallsOutstanding,
	CallsOpen,
	AvgDaysFaultToApproved,
	AvgDaysApprovedToCompleted,
	SitesWithZeroCalls,
	SitesWithOverFiveCalls,
	CallsOnHold,
	DMSCallsOnHold,
	IDraughtCallsOnHold,
	CallsOnHoldBrulinesIssue,
	CallsOnHoldClientIssue,
	FlowmetersInstalled,
	DMSFlowmetersInstalledTotal,
	IDraughtFlowmetersInstalledTotal,
	DMSFlowmetersInstalledInPeriod,
	IDraughtFlowmetersInstalledInPeriod,
	FlowmetersCleaned,
	CallsRaised,
	CallsCancelled,
	CallsAborted,
	AvgDMSDaysApprovedToCompleted,
	AvgIDraughtDaysApprovedToCompleted,
	CalFailureNoProduct,
	CalFailureFobbing,
	CalFailureDispenseIssue,
	CallsCompletedLast6Periods,
	AvgDMSDaysApprovedToCompletedLast6Periods,
	AvgIDraughtDaysApprovedToCompletedLast6Periods,
	CallsInProgress,
	CallsOpenAvgDays,
	CallsInProgressAvgDays,
	CallsOpenOutsideSLA,
	CallsOpenOutsideSLAAvgDays,
	CallsOpenOutsideSLADMS,
	CallsOpenOutsideSLADMSAvgDays,
	CallsOpenOutsideSLAIDraught,
	CallsOpenOutsideSLAIDraughtAvgDays,
	DMSSitesWithZeroCalls,
	IDraughtSitesWithZeroCalls,
	DMSSitesWithOverFiveCalls,
	IDraughtSitesWithOverFiveCalls,
	DMSCallsCompletedPrevious6Periods,
	IDraughtCallsCompletedPrevious6Periods,
	SNACallsDMSTotal,
	SNACallsDMSInSLA,
	SNACallsDMSOutSLA,
	SNACallsIDraughtTotal,
	SNACallsIDraughtInSLA,
	SNACallsIDraughtOutSLA,
	CallsRaisedDMS,
	CallsRaisedIDraught,
	CallsOutstandingDMS,
	CallsOutstandingIDraught,
	CallsOpenDMS,
	CallsOpenIDraught,
	CallsInProgressDMS,
	CallsInProgressIDraught,
	CallsInProgressAvgDaysDMS,
	CallsInProgressAvgDaysIDraught,
	DMSCallsOnHoldBrulinesIssue,
	IDraughtCallsOnHoldBrulinesIssue,
	DMSCallsOnHoldClientIssue,
	IDraughtCallsOnHoldClientIssue,
	FlowmetersCleanedDMS,
	FlowmetersCleanedIDraught,
	CallsCancelledDMS,
	CallsCancelledIDraught,
	CallsAbortedDMS,
	CallsAbortedIDraught,
	CalibrationFailureNoProductDMS,
	CalibrationFailureNoProductIDraught,
	CalibrationFailureFobbingDMS,
	CalibrationFailureFobbingIDraught,
	CalibrationFailureDispenseIssueDMS,
	CalibrationFailureDispenseIssueIDraught,
	CallsOpenAvgDaysDMS,
	CallsOpenAvgDaysIDraught,
	PriorityCallsOpenDMS,
	PriorityCallsRaisedDMS,
	PriorityCallsOutstandingDMS,
	PriorityCallsInProgressDMS,
	PriorityCallsInProgressAvgDaysDMS,
	PriorityCallsOpenOutsideSLADMS,
	PriorityCallsOpenAvgDaysDMS,
	PriorityCallsOpenOutsideSLADMSAvgDays,
	PriorityCallsOpenIDraught,
	PriorityCallsRaisedIDraught,
	PriorityCallsOutstandingIDraught,
	PriorityCallsInProgressIDraught,
	PriorityCallsInProgressAvgDaysIDraught,
	PriorityCallsOpenOutsideSLAIDraught,
	PriorityCallsOpenAvgDaysIDraught,
	PriorityCallsOpenOutsideSLAIDraughtAvgDays,
	DMSSitesAllInclusive,
	IDraughtSitesAllInclusive,
	DMSSitesPAYGOther,
	IDraughtSitesPAYGOther,
	DMSSitesOver5Years,
	IDraughtSitesOver5Years,
	DMSSitesUnder5Years,
	IDraughtSitesUnder5Years
	)
VALUES
(	@DatabaseID,
	@CustomerName,
	CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @Today))),
	ISNULL(@DMSSites, 0),
	ISNULL(@IDraughtSites, 0),
	ISNULL(@DMSCompletedCalls, 0),
	ISNULL(@IDraughtCompletedCalls, 0),
	ISNULL(@CallsCompleted, 0),
	ISNULL(@DMSCompletedCallsInSLA, 0),
	ISNULL(@IDraughtCompletedCallsInSLA, 0),
	ISNULL(@DMSCompletedCallsOutSLA, 0),
	ISNULL(@IDraughtCompletedCallsOutSLA, 0),
	ISNULL(@SNACallsTotal, 0),
	ISNULL(@SNACallsInSLA, 0),
	ISNULL(@SNACallsOutSLA, 0),
	ISNULL(@CallsOutstanding, 0),
	ISNULL(@CallsOpen, 0),
	0, --AvgDaysFaultToApproved
	ISNULL(@AvgDaysApprovedToCompleted, 0),
	ISNULL(@SitesWithZeroCalls, 0),
	ISNULL(@SitesWithOver5Calls, 0),
	ISNULL(@CallsOnHold, 0),
	ISNULL(@DMSCallsOnHold, 0),
	ISNULL(@IDraughtCallsOnHold, 0),
	ISNULL(@CallsOnHoldBrulinesIssue, 0),
	ISNULL(@CallsOnHoldClientIssue, 0),
	ISNULL(@FlowmetersInstalled, 0),
	ISNULL(@DMSFlowmetersInstalledTotal, 0),
	ISNULL(@IDraughtFlowmetersInstalledTotal, 0),
	ISNULL(@DMSFlowmetersInstalledInPeriod, 0),
	ISNULL(@IDraughtFlowmetersInstalledInPeriod, 0),
	ISNULL(@FlowmetersCleaned, 0),
	ISNULL(@CallsRaised, 0),
	ISNULL(@CallsCancelled, 0),
	ISNULL(@CallsAborted, 0),
	ISNULL(@AvgDMSDaysApprovedToCompleted, 0),
	ISNULL(@AvgIDraughtDaysApprovedToCompleted, 0),
	ISNULL(@CalibrationFailureNoProduct, 0),
	ISNULL(@CalibrationFailureFobbing, 0),
	ISNULL(@CalibrationFailureDispenseIssue, 0),
	ISNULL(@CallsCompletedPrevious6Periods, 0),
	ISNULL(@AvgDMSDaysApprovedToCompletedPrevious6Periods, 0),
	ISNULL(@AvgIDraughtDaysApprovedToCompletedPrevious6Periods, 0),
	ISNULL(@CallsInProgress, 0),
	ISNULL(@CallsOpenDays, 0),
	ISNULL(@CallsInProgressDays, 0),
	ISNULL(@CallsOpenOutsideSLA, 0),
	ISNULL(@CallsOpenDaysOutsideSLA, 0),
	ISNULL(@CallsOpenOutsideSLADMS, 0),
	ISNULL(@CallsOpenDaysOutsideSLADMS, 0),
	ISNULL(@CallsOpenOutsideSLAIDraught, 0),
	ISNULL(@CallsOpenDaysOutsideSLAIDraught, 0),
	ISNULL(@DMSSitesWithZeroCalls, 0),
	ISNULL(@IDraughtSitesWithZeroCalls, 0),
	ISNULL(@DMSSitesWithOver5Calls, 0),
	ISNULL(@IDraughtSitesWithOver5Calls, 0),
	ISNULL(@DMSCallsCompletedPrevious6Periods, 0),
	ISNULL(@IDraughtCallsCompletedPrevious6Periods, 0),
	ISNULL(@SNACallsDMSTotal, 0),
	ISNULL(@SNACallsDMSInSLA, 0),
	ISNULL(@SNACallsDMSOutSLA, 0),
	ISNULL(@SNACallsIDraughtTotal, 0),
	ISNULL(@SNACallsIDraughtInSLA, 0),
	ISNULL(@SNACallsIDraughtOutSLA, 0),
	ISNULL(@CallsRaisedDMS, 0),
	ISNULL(@CallsRaisedIDraught, 0),
	ISNULL(@CallsOutstandingDMS, 0),
	ISNULL(@CallsOutstandingIDraught, 0),
	ISNULL(@CallsOpenDMS, 0),
	ISNULL(@CallsOpenIDraught, 0),
	ISNULL(@CallsInProgressDMS, 0),
	ISNULL(@CallsInProgressIDraught, 0),
	ISNULL(@CallsInProgressAvgDaysDMS, 0),
	ISNULL(@CallsInProgressAvgDaysIDraught, 0),
	ISNULL(@DMSCallsOnHoldBrulinesIssue, 0),
	ISNULL(@IDraughtCallsOnHoldBrulinesIssue, 0),
	ISNULL(@DMSCallsOnHoldClientIssue, 0),
	ISNULL(@IDraughtCallsOnHoldClientIssue, 0),
	ISNULL(@FlowmetersCleanedDMS, 0),
	ISNULL(@FlowmetersCleanedIDraught, 0),
	ISNULL(@CallsCancelledDMS, 0),
	ISNULL(@CallsCancelledIDraught, 0),
	ISNULL(@CallsAbortedDMS, 0),
	ISNULL(@CallsAbortedIDraught, 0), 
	ISNULL(@CalibrationFailureNoProductDMS, 0),
	ISNULL(@CalibrationFailureNoProductIDraught, 0),
	ISNULL(@CalibrationFailureFobbingDMS, 0),
	ISNULL(@CalibrationFailureFobbingIDraught, 0),
	ISNULL(@CalibrationFailureDispenseIssueDMS, 0),
	ISNULL(@CalibrationFailureDispenseIssueIDraught, 0),
	ISNULL(@CallsOpenDaysDMS, 0),
	ISNULL(@CallsOpenDaysIDraught, 0),
	ISNULL(@PriorityCallsOpenDMS, 0),
	ISNULL(@PriorityCallsRaisedDMS, 0),
	ISNULL(@PriorityCallsOutstandingDMS, 0),
	ISNULL(@PriorityCallsInProgressDMS, 0),
	ISNULL(@PriorityCallsInProgressAvgDaysDMS, 0),
	ISNULL(@PriorityCallsOpenOutsideSLADMS, 0),
	ISNULL(@PriorityCallsOpenAvgDaysDMS, 0),
	ISNULL(@PriorityCallsOpenOutsideSLADMSAvgDays, 0),
	ISNULL(@PriorityCallsOpenIDraught, 0),
	ISNULL(@PriorityCallsRaisedIDraught, 0),
	ISNULL(@PriorityCallsOutstandingIDraught, 0),
	ISNULL(@PriorityCallsInProgressIDraught, 0),
	ISNULL(@PriorityCallsInProgressAvgDaysIDraught, 0),
	ISNULL(@PriorityCallsOpenOutsideSLAIDraught, 0),
	ISNULL(@PriorityCallsOpenAvgDaysIDraught, 0),
	ISNULL(@PriorityCallsOpenOutsideSLAIDraughtAvgDays, 0),
	ISNULL(@DMSSitesAllInclusive, 0),
	ISNULL(@IDraughtSitesAllInclusive, 0),
	ISNULL(@DMSSitesPAYGOther, 0),
	ISNULL(@IDraughtSitesPAYGOther, 0),
	ISNULL(@DMSSitesOver5Years, 0),
	ISNULL(@IDraughtSitesOver5Years, 0),
	ISNULL(@DMSSitesUnder5Years, 0),
	ISNULL(@IDraughtSitesUnder5Years, 0)
	)

IF @AddToEstateTotals = 1
BEGIN

	EXEC [EDISSQL1\SQL1].[ServiceLogger].dbo.AddPeriodCacheCustomerCalls @Date,
																		 @DatabaseID,
																		 @DMSSites,
																		@IDraughtSites,
																		@DMSCompletedCalls,
																		@IDraughtCompletedCalls,
																		@CallsCompleted,
																		@DMSCompletedCallsInSLA,
																		@IDraughtCompletedCallsInSLA,
																		@DMSCompletedCallsOutSLA,
																		@IDraughtCompletedCallsOutSLA,
																		@SNACallsTotal,
																		@SNACallsInSLA,
																		@SNACallsOutSLA,
																		@CallsOutstanding,
																		@CallsOpen,
																		0, --AvgDaysFaultToApproved
																		@TotalDaysApprovedToCompleted,
																		@SitesWithZeroCalls,
																		@SitesWithOver5Calls,
																		@CallsOnHold,
																		@DMSCallsOnHold,
																		@IDraughtCallsOnHold,
																		@CallsOnHoldBrulinesIssue,
																		@CallsOnHoldClientIssue,
																		@FlowmetersInstalled,
																		@DMSFlowmetersInstalledTotal,
																		@IDraughtFlowmetersInstalledTotal,
																		@DMSFlowmetersInstalledInPeriod,
																		@IDraughtFlowmetersInstalledInPeriod,
																		@FlowmetersCleaned,
																		@CallsRaised,
																		@CallsCancelled,
																		@CallsAborted,
																		@TotalDMSDaysApprovedToCompleted,
																		@TotalIDraughtDaysApprovedToCompleted,
																		@CalibrationFailureNoProduct,
																		@CalibrationFailureFobbing,
																		@CalibrationFailureDispenseIssue,
																		@CallsCompletedPrevious6Periods,
																		@TotalDMSDaysApprovedToCompletedPrevious6Periods,
																		@TotalIDraughtDaysApprovedToCompletedPrevious6Periods,
																		@CallsInProgress,
																		@TotalCallsOpenDays,
																		@TotalCallsInProgressDays,
																		@CallsOpenOutsideSLA,
																		@TotalCallsOpenDaysOutsideSLA,
																		@CallsOpenOutsideSLADMS,
																		@TotalCallsOpenDaysOutsideSLADMS,
																		@CallsOpenOutsideSLAIDraught,
																		@TotalCallsOpenDaysOutsideSLAIDraught,
																		@DMSSitesWithZeroCalls,
																		@IDraughtSitesWithZeroCalls,
																		@DMSSitesWithOver5Calls,
																		@IDraughtSitesWithOver5Calls,
																		@DMSCallsCompletedPrevious6Periods,
																		@IDraughtCallsCompletedPrevious6Periods,
																		@SNACallsDMSTotal,
																		@SNACallsDMSInSLA,
																		@SNACallsDMSOutSLA,
																		@SNACallsIDraughtTotal,
																		@SNACallsIDraughtInSLA,
																		@SNACallsIDraughtOutSLA,
																		@CallsRaisedDMS,
																		@CallsRaisedIDraught,
																		@CallsOutstandingDMS,
																		@CallsOutstandingIDraught,
																		@CallsOpenDMS,
																		@CallsOpenIDraught,
																		@CallsInProgressDMS,
																		@CallsInProgressIDraught,
																		@TotalCallsInProgressDaysDMS,
																		@TotalCallsInProgressDaysIDraught,
																		@DMSCallsOnHoldBrulinesIssue,
																		@IDraughtCallsOnHoldBrulinesIssue,
																		@DMSCallsOnHoldClientIssue,
																		@IDraughtCallsOnHoldClientIssue,
																		@FlowmetersCleanedDMS,
																		@FlowmetersCleanedIDraught,
																		@CallsCancelledDMS,
																		@CallsCancelledIDraught,
																		@CallsAbortedDMS,
																		@CallsAbortedIDraught,
																		@CalibrationFailureNoProductDMS,
																		@CalibrationFailureNoProductIDraught,
																		@CalibrationFailureFobbingDMS,
																		@CalibrationFailureFobbingIDraught,
																		@CalibrationFailureDispenseIssueDMS,
																		@CalibrationFailureDispenseIssueIDraught,
																		@CallsOpenDaysDMS,
																		@CallsOpenDaysIDraught,
																		@PriorityCallsOpenDMS,
																		@PriorityCallsRaisedDMS,
																		@PriorityCallsOutstandingDMS,
																		@PriorityCallsInProgressDMS,
																		@TotalPriorityCallsInProgressAvgDaysDMS,
																		@PriorityCallsOpenOutsideSLADMS,
																		@TotalPriorityCallsOpenAvgDaysDMS,
																		@TotalPriorityCallsOpenOutsideSLADMSAvgDays,
																		@PriorityCallsOpenIDraught,
																		@PriorityCallsRaisedIDraught,
																		@PriorityCallsOutstandingIDraught,
																		@PriorityCallsInProgressIDraught,
																		@TotalPriorityCallsInProgressAvgDaysIDraught,
																		@PriorityCallsOpenOutsideSLAIDraught,
																		@TotalPriorityCallsOpenAvgDaysIDraught,
																		@TotalPriorityCallsOpenOutsideSLAIDraughtAvgDays,
																		@DMSSitesAllInclusive,
																		@IDraughtSitesAllInclusive,
																		@DMSSitesPAYGOther,
																		@IDraughtSitesPAYGOther,
																		@DMSSitesOver5Years,
																		@IDraughtSitesOver5Years,
																		@DMSSitesUnder5Years,
																		@IDraughtSitesUnder5Years


END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheCallsRebuild] TO PUBLIC
    AS [dbo];

