CREATE PROCEDURE [dbo].[ComplianceReportGetSiteHotSpot]
(
	@EDISID		INT,
	@DateTo		DATETIME = NULL,
	@Weeks		INT = 18
)
AS

	SET FMTONLY OFF;

	DECLARE @endDate datetime


	IF @DateTo IS NULL
		SET @DateTo = GETDATE()

	IF DATEPART(dw, @DateTo) <> 7
		SET @endDate = DATEADD(wk, DATEDIFF(wk, 6, @DateTo), 6)
	ELSE
		SET @endDate = @DateTo
		
	
	DECLARE @reportStart datetime = DATEADD(week, 0 - @Weeks, @endDate)
	DECLARE @startDate datetime = DATEADD(wk, DATEDIFF(wk, 0, @reportStart), 0)

	DECLARE @dates table
	(
		[Date] datetime
	)

	DECLARE @tempDate datetime = @startDate

	while @tempDate <= @endDate
	begin
		INSERT INTO @dates VALUES(@tempDate)

		SET @tempDate = DATEADD(day, 1, @tempDate)
	end

	DECLARE @shift table
	(
		[Shift] int
	)

	DECLARE @shiftNumber int = 1

	while @shiftNumber <= 24
	begin
		insert into @shift values (@shiftNumber)

		SET @shiftNumber = @shiftNumber + 1
	end

	CREATE TABLE #ShiftDates
	(
		[Date] datetime,
		[Shift] int
	)

	INSERT INTO #ShiftDates
	SELECT d.[Date], s.[Shift] FROM @dates d, @shift s

	CREATE TABLE #SiteDetails
	(
		EDISID int,
		SiteID varchar(255),
		Name varchar(255),
		Town varchar(255),
		PostCode varchar(255),
		BDM varchar(255)
	)

	
	CREATE TABLE #ReportSites
	(
		EDISID int
	)

	INSERT INTO #ReportSites
	select	distinct ISNULL(sgs2.EDISID, s.EDISID)
	from			dbo.[Sites] s
	inner join dbo.SiteGroupSites sgs on s.EDISID = sgs.EDISID
	inner join dbo.SiteGroups sg on sgs.SiteGroupID = sg.ID and sg.TypeID = 1
	inner join dbo.SiteGroupSites sgs2 on sgs.SiteGroupID = sgs2.SiteGroupID
	inner join dbo.[Sites] s2 on sgs2.EDISID = s2.EDISID
	where s.EDISID = @EDISID and ISNULL(s2.Hidden, s.Hidden) = 0

	IF NOT EXISTS(SELECT 1 FROM #ReportSites)
		INSERT INTO #ReportSites VALUES (@EDISID)

	DECLARE @SiteID varchar(255)
	DECLARE @SiteName varchar(255)
	DECLARE @SiteTown varchar(255)
	DECLARE @BDM varchar(255)

	INSERT INTO #SiteDetails EXEC dbo.GetSitesForReport 0, NULL, @EDISID

	SELECT TOP 1  @SiteID = SiteID, @SiteName = [Name], @SiteTown = Town, @BDM = BDM FROM #SiteDetails

	CREATE TABLE #ReportData
	(
		[Date] datetime,
		[Shift] int,
		Quantity float
	)

	--INSERT INTO #ReportData EXEC [dbo].[GetDailyShiftDispensed] @EDISID, @startDate, @endDate

	INSERT INTO #ReportData
	SELECT MasterDates.[Date], 
		DLData.Shift,
		SUM(Quantity) AS Quantity
	FROM dbo.DLData
	INNER JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
	INNER JOIN #ReportSites rs on MasterDates.EDISID = rs.EDISID
	WHERE MasterDates.[Date] BETWEEN @startDate AND @endDate
	GROUP BY MasterDates.[Date], DLData.Shift

	DECLARE @MaxDispense float

	SELECT @MaxDispense = MAX(Quantity)
	FROM
	(
		SELECT	SUM(Quantity) As Quantity
		FROM	#ReportData
		GROUP BY [Shift], DATENAME(weekday,[Date])
	) AS GroupedQuantity

	SELECT	@SiteID AS SiteID,
			@SiteName AS SiteName,
			@SiteTown AS SiteTown,
			@BDM AS BDM,
			DATENAME(weekday,sd.[Date]) AS [DayOfWeek],
			sd.[Shift],
			ROUND(ISNULL(SUM(Quantity),0),2) AS [Quantity],
			@MaxDispense As [MaxDispense], 
			DATEPART(dw, sd.[Date]) AS [DayOfWeekNo]
	FROM	#ShiftDates sd
	LEFT OUTER JOIN #ReportData rd on sd.[Date] = rd.[Date] and sd.[Shift] = rd.[Shift]
	GROUP BY sd.[Shift], DATENAME(weekday,sd.[Date]), DATEPART(dw, sd.[Date])
	ORDER BY DATEPART(dw, sd.[Date]) ,sd.[Shift]

	DROP TABLE #ReportSites
	DROP TABLE #SiteDetails
	DROP TABLE #ShiftDates
	DROP TABLE #ReportData
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ComplianceReportGetSiteHotSpot] TO PUBLIC
    AS [dbo];

