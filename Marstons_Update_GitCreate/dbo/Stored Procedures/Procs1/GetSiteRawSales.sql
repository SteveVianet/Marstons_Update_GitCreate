CREATE PROCEDURE [dbo].[GetSiteRawSales]
(
	@EDISID			INT,
	@From				DATETIME,
	@To				DATETIME,
	@GroupingInterval		INT,
	@IncludeCasks			BIT,
	@IncludeKegs			BIT,
	@IncludeMetric			BIT,
	@MinimumQuantity		FLOAT = NULL,
	@MaximumQuantity		FLOAT= NULL
)
AS

SET NOCOUNT ON

DECLARE @TradingSold TABLE(EDISID		INT,
				   DateAndTime		DATETIME,
				   TradingDateAndTime DATETIME,
				   ProductID 		INT,
				   Quantity		FLOAT,
				   SaleIdent 		VARCHAR(255))
DECLARE @TradingDayBeginsAt INT
SET @TradingDayBeginsAt = 5

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

-- Get sales for period and bodge about into 'trading hours'
-- DateAndTime is the actual date and time
-- TradingDateAndTime is the actual time, but the date is the 'trading date'
-- Note that we grab an extra day (because we need the first few hours from it)
INSERT INTO @TradingSold
(
EDISID,
[DateAndTime],
TradingDateAndTime,
ProductID,
Quantity,
SaleIdent)
SELECT  MasterDates.EDISID,
	CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, Sales.[SaleTime]), DATEADD(mi, DATEPART(mi, Sales.[SaleTime]), DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]))), 20),
	DATEADD(Second, DATEPART(Second, Sales.[SaleTime]), DATEADD(Minute, DATEPART(Minute, Sales.[SaleTime]), DATEADD(Hour, DATEPART(Hour, Sales.[SaleTime]), CAST(CONVERT(VARCHAR(10), DATEADD(hh,@TradingDayBeginsAt*-1,CONVERT(VARCHAR(19), DATEADD(ss, DATEPART(ss, Sales.[SaleTime]), DATEADD(mi, DATEPART(mi, Sales.[SaleTime]), DATEADD(hh, DATEPART(hh, Sales.[SaleTime]), MasterDates.[Date]))), 20)), 12) AS DATETIME)))) AS TradingDateAndTime,
	ProductID,
	Quantity,
	SaleIdent
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Products.[ID] = Sales.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(dd,1,@To)
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Quantity >= @MinimumQuantity OR @MinimumQuantity IS NULL)
AND (Quantity <= @MaximumQuantity OR @MaximumQuantity IS NULL)

-- Delete the first few hours from the first day, as that is the previous 'trading day'
DELETE
FROM @TradingSold
WHERE DateAndTime < DATEADD(hh,@TradingDayBeginsAt,@From)

-- Delete the first few hours from the 'last+1' day, as that is the next 'trading day'
DELETE
FROM @TradingSold
WHERE DateAndTime >= DATEADD(hh,@TradingDayBeginsAt,DATEADD(dd,1,@To))

IF @GroupingInterval = 0
BEGIN
	SELECT  EDISID,
		[DateAndTime],
		TradingDateAndTime,
		ProductID,
		Quantity,
		SaleIdent
	FROM @TradingSold
	ORDER BY DateAndTime
END
ELSE
BEGIN
	SELECT   CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME) AS DateAndTime,
	   	 CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME) AS TradingDateAndTime,
		 ProductID, 
		 SUM(Quantity) AS Quantity
	FROM @TradingSold
	GROUP BY CAST(STR(DATEPART(year,DateAndTime),4) + '-' + STR(DATEPART(month,DateAndTime),LEN(DATEPART(month,DateAndTime))) + '-' + STR(DATEPART(day,DateAndTime),LEN(DATEPART(day,DateAndTime))) + ' ' + STR(DATEPART(hour,DateAndTime),LEN(DATEPART(hour,DateAndTime))) + ':' + STR((DATEPART(minute, DateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,DateAndTime))) + ':00' AS DATETIME),
		 CAST(STR(DATEPART(year,TradingDateAndTime),4) + '-' + STR(DATEPART(month,TradingDateAndTime),LEN(DATEPART(month,TradingDateAndTime))) + '-' + STR(DATEPART(day,TradingDateAndTime),LEN(DATEPART(day,TradingDateAndTime))) + ' ' + STR(DATEPART(hour,TradingDateAndTime),LEN(DATEPART(hour,TradingDateAndTime))) + ':' + STR((DATEPART(minute, TradingDateAndTime)/@GroupingInterval)*@GroupingInterval,LEN(DATEPART(minute,TradingDateAndTime))) + ':00' AS DATETIME),
		 ProductID
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRawSales] TO PUBLIC
    AS [dbo];

