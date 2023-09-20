CREATE PROCEDURE [dbo].[GetYearCompletedCallsByMonth]
(
	@Quality		  BIT = 0,
	@AddToEstateTotal BIT = 0
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @Today DATETIME
DECLARE @StartOfYear DATETIME
DECLARE @StartOfMonth DATETIME
DECLARE @StartOfPreviousPeriod DATETIME
DECLARE @EndOfPreviousPeriod DATETIME
DECLARE @MonthlyCalls TABLE(DatabaseID INT, [Month] DATETIME, MonthEnd DATETIME, Period INT, Quality BIT, CompletedCallsInSLA INT, CompletedCallsOutSLA INT, CompletedCalls INT)
DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

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
							
INSERT INTO #Periods
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetPeriods 1

INSERT INTO #CallFaultTypes
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallFaultTypes

SET @Today = GETDATE()

--SET @StartOfYear =  CAST(CAST(CASE WHEN MONTH(@Today) < 4 THEN YEAR(DATEADD(year, -1, @Today)) ELSE YEAR(@Today) END AS VARCHAR(4)) + '/04/01' AS DATETIME)
                
--SET @StartOfMonth =  CAST(CAST(YEAR(@Today) AS VARCHAR(4)) + '/' + 
--                CAST(MONTH(@Today) AS VARCHAR(2)) + '/01' AS DATETIME)

SELECT TOP 1 @StartOfYear = StartDate
FROM #Periods
ORDER BY StartDate ASC

--SET @StartOfYear = DATEADD(YEAR, -1, @StartOfMonth)

SELECT TOP 1 @StartOfPreviousPeriod = StartDate, @EndOfPreviousPeriod = EndDate
FROM #Periods
ORDER BY StartDate DESC

--SET @StartOfPreviousPeriod = DATEADD(MONTH, -1, @StartOfMonth)
--SET @EndOfPreviousPeriod = DATEADD(SECOND, -1, @StartOfMonth)

DECLARE @Calls TABLE([ID] INT NOT NULL, EDISID INT NOT NULL, StatusID INT NOT NULL, LatestStatusChangeDate DATETIME NOT NULL, Quality BIT NOT NULL, AbortReasonID INT NOT NULL, PlanningIssueID INT NOT NULL,  SLA INT NOT NULL, WeekdaysTaken INT NOT NULL, InSLA BIT)
--DECLARE @MonthsInYear TABLE([Month] DATETIME)

--DECLARE @Date DATETIME
--SET @Date = @StartOfYear
--WHILE @Date < @StartOfMonth
--BEGIN
--INSERT INTO @MonthsInYear ([Month]) VALUES (@Date)
--SELECT @Date = DATEADD(MONTH, 1, @Date)
--END

--INSERT INTO @Calls
--([ID], EDISID, StatusID,LatestStatusChangeDate, Quality, AbortReasonID, PlanningIssueID, SLA, WeekdaysTaken)
--SELECT CallStatusHistory.CallID, Sites.EDISID, StatusID, ClosedOn, Quality, AbortReasonID, PlanningIssueID,
--		MAX(CASE WHEN OverrideSLA > 0 THEN OverrideSLA
--			 WHEN CallTypeID = 2 AND SalesReference LIKE 'TRA%'	THEN 21
--		     WHEN CallTypeID = 2 AND SalesReference NOT LIKE 'TRA%'THEN 7
--		     ELSE COALESCE(CallFaults.SLA, CallFaultTypes.SLA, 0) END),
--		dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), ClosedOn)
--FROM CallStatusHistory
--JOIN
--(
--SELECT CallID, MAX(ChangedOn) AS LatestChangeDate
--FROM CallStatusHistory
--GROUP BY CallID
--) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
--AND LatestCallChanges.LatestChangeDate = CallStatusHistory.ChangedOn
--JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
--JOIN Sites ON Sites.EDISID = Calls.EDISID
--LEFT JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
--LEFT JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
--WHERE Calls.AbortReasonID <> 3
----AND Calls.PlanningIssueID = 1
----AND StatusID IN (4, 5)
--AND ClosedOn IS NOT NULL
--GROUP BY CallStatusHistory.CallID, Sites.EDISID, StatusID, ClosedOn, Quality, AbortReasonID, PlanningIssueID, dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), ClosedOn)
--ORDER BY CallStatusHistory.CallID

INSERT INTO @Calls
([ID], EDISID, StatusID,LatestStatusChangeDate, Quality, AbortReasonID, PlanningIssueID, SLA, WeekdaysTaken, InSLA)
SELECT [ID], Sites.EDISID, 4, ClosedOn, Quality, AbortReasonID, PlanningIssueID, OverrideSLA, DaysToComplete, CallWithinSLA
FROM CallsSLA
JOIN Sites ON Sites.EDISID = CallsSLA.EDISID
WHERE AbortReasonID <> 3
--AND Calls.PlanningIssueID = 1
--AND StatusID IN (4, 5)
AND ClosedOn IS NOT NULL

DELETE
FROM @Calls
WHERE [ID] IN
(
	SELECT Calls.[ID]
	FROM @Calls AS Calls
	JOIN CallFaults ON CallFaults.CallID = Calls.[ID]
	JOIN #CallFaultTypes AS CallFaultTypes ON CallFaultTypes.[ID] = CallFaults.FaultTypeID
	WHERE ExcludeFromReporting = 1
)

DROP TABLE #CallFaultTypes

INSERT INTO @MonthlyCalls
(DatabaseID, [Month], MonthEnd, Period, Quality, CompletedCallsInSLA, CompletedCallsOutSLA, CompletedCalls)
SELECT @DatabaseID,
	   StartDate,
	   EndDate,
	   Period,
	   --[Month],
	   --CASE MONTH([Month]) WHEN 4 THEN 1
				--		   WHEN 5 THEN 2
				--		   WHEN 6 THEN 3
				--		   WHEN 7 THEN 4
				--		   WHEN 8 THEN 5
				--		   WHEN 9 THEN 6
				--		   WHEN 10 THEN 7
				--		   WHEN 11 THEN 8
				--		   WHEN 12 THEN 9
				--		   WHEN 1 THEN 10
				--		   WHEN 2 THEN 11
				--		   WHEN 3 THEN 12 END AS Period,
	   @Quality AS Quality,
	   SUM(CASE WHEN InSLA = 1 AND AbortReasonID = 0 AND PlanningIssueID = 1 THEN 1 ELSE 0 END) AS CompletedCallsInSLA,
	   SUM(CASE WHEN InSLA = 0 AND AbortReasonID = 0 AND PlanningIssueID = 1 THEN 1 ELSE 0 END) AS CompletedCallsOutSLA,
	   COUNT(Calls.[ID]) AS CompletedCalls
--FROM @MonthsInYear AS MonthsInYear
FROM #Periods AS Periods
LEFT JOIN @Calls AS Calls ON Calls.LatestStatusChangeDate BETWEEN Periods.StartDate AND Periods.EndDate AND Quality = @Quality
--LEFT JOIN @Calls AS Calls ON (CAST(CAST(YEAR(LatestStatusChangeDate) AS VARCHAR(4)) + '/' + 
--                CAST(MONTH(LatestStatusChangeDate) AS VARCHAR(2)) + '/01' AS DATETIME)) = MonthsInYear.[Month] AND Quality = @Quality
--GROUP BY [Month]
--ORDER BY [Month]
GROUP BY StartDate, EndDate, Period
ORDER BY StartDate, EndDate, Period

DROP TABLE #Periods

IF @AddToEstateTotal = 1
BEGIN
	INSERT INTO [EDISSQL1\SQL1].ServiceLogger.dbo.PeriodCacheEstateYearlyCalls
	(DatabaseID, [Month], Quality, Period, CallsCompleted, CallsCompletedInSLA, CallsCompletedOutSLA, MonthEnd)
	SELECT DatabaseID,
			[Month],
			Quality,
			Period,
			CompletedCalls,
			CompletedCallsInSLA,
			CompletedCallsOutSLA,
			MonthEnd
	FROM @MonthlyCalls
END

SELECT DatabaseID,
		[Month],
		MonthEnd,
		Quality,
		Period,
		CompletedCalls,
		CompletedCallsInSLA,
		CompletedCallsOutSLA
FROM @MonthlyCalls

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetYearCompletedCallsByMonth] TO PUBLIC
    AS [dbo];

