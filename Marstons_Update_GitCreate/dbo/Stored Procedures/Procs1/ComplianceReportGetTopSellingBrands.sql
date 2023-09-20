CREATE PROCEDURE [dbo].[ComplianceReportGetTopSellingBrands]
(
	@EDISID		INT,
	@DateTo		DATETIME = NULL,
	@Weeks		INT = 18
)
AS
	SET DATEFIRST 1;
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

/* Original SELECT */
	--SELECT	
	--	pctd.EDISID, 
	--	pctd.TradingDay, 
	--	pctd.Pump, 
	--	pctd.Volume, 
	--	p.[Description] 
	--FROM	PeriodCacheTradingDispense pctd
	--INNER JOIN Products p on pctd.ProductID = p.ID
	--WHERE	TradingDay BETWEEN @startDate AND @endDate
	--AND		EDISID = @EDISID



/* SELECT using DLData table */
--SELECT md.EDISID
--	, md.Date
--	, p.Description Product
--	, SUM(dld.Quantity) 
--FROM MasterDates md 
--	JOIN DLData dld ON dld.DownloadID = md.ID
--	JOIN Products p ON p.ID = dld.Product
--WHERE md.Date BETWEEN @startDate AND @endDate 
--	AND md.EDISID = @EDISID
--GROUP BY md.EDISID, md.Date, p.Description



/* SELECT using PeriodCacheVariance */
SELECT 
    pcv.EDISID
	, p.Description Products
	, SUM(pcv.Dispensed)/8 Gallons
FROM PeriodCacheVariance pcv 
	JOIN Products p ON p.ID = pcv.ProductID
WHERE pcv.WeekCommencing BETWEEN @startDate AND @endDate 
	AND pcv.EDISID = @EDISID
GROUP BY pcv.EDISID, p.Description
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ComplianceReportGetTopSellingBrands] TO PUBLIC
    AS [dbo];

