CREATE PROCEDURE [dbo].[GetWebSiteDeliveryVariance]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT,
	@UseTradingDays BIT = 1
)

AS

SET NOCOUNT ON

-- Change the first day of the week to Monday (default is Sunday/7)
SET DATEFIRST 1

CREATE TABLE #TradingDispensed (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, LiquidType INT NOT NULL, Quantity FLOAT NOT NULL)
CREATE CLUSTERED INDEX IX_TRADINGDISPENSED_LIQUIDTYPE_PRODUCTID ON #TradingDispensed (LiquidType, ProductID)
CREATE TABLE #TradingDelivered (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
CREATE CLUSTERED INDEX IX_TRADINGDELIVERED_PRODUCTID ON #TradingDelivered (ProductID)

DECLARE @BeerDispensed TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @BeerDelivered TABLE (TradingDate DATETIME NOT NULL, ProductID INT NOT NULL, Quantity FLOAT NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL PRIMARY KEY, PumpOffset INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)
DECLARE @SiteOnline  DATETIME
DECLARE @IsIDraught BIT

SELECT @IsIDraught = Quality, @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

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

INSERT INTO @SitePumpCounts (EDISID, MaxPump)
SELECT PumpSetup.EDISID, MAX(Pump)
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE (ValidFrom <= @To)
AND (ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
GROUP BY PumpSetup.EDISID

INSERT INTO @SitePumpOffsets (EDISID, PumpOffset)
SELECT MainCounts.EDISID, COALESCE(QuaternaryCounts.MaxPump+TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, TertiaryCounts.MaxPump+SecondaryCounts.MaxPump, SecondaryCounts.MaxPump, 0)
FROM @SitePumpCounts AS MainCounts
LEFT JOIN @SitePumpCounts AS SecondaryCounts ON SecondaryCounts.Counter+1 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS TertiaryCounts ON TertiaryCounts.Counter+2 = MainCounts.Counter
LEFT JOIN @SitePumpCounts AS QuaternaryCounts ON QuaternaryCounts.Counter+3 = MainCounts.Counter

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries
INSERT INTO @PrimaryProducts
(ProductID, PrimaryProductID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

-- Get dispense for period
IF @IsIDraught = 1
BEGIN
	INSERT INTO #TradingDispensed
	(TradingDate, ProductID, LiquidType, Quantity)
	SELECT	DATEADD(Hour, DATEPART(Hour, [StartTime]), TradingDay) AS [TradingDate],
			ISNULL(PrimaryProducts.PrimaryProductID, DispenseActions.Product) AS ProductID,
			LiquidType,
			Pints
	FROM DispenseActions
	JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = DispenseActions.EDISID
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DispenseActions.Product
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = DispenseActions.EDISID
	WHERE TradingDay BETWEEN @From AND @To
	AND TradingDay >= @SiteOnline
	AND DispenseActions.LiquidType IN (2,5)
	
END
ELSE
BEGIN
	IF @UseTradingDays = 1
	BEGIN 
		INSERT INTO #TradingDispensed
		(TradingDate, ProductID, LiquidType, Quantity)
		SELECT	DATEADD(Hour, Shift-1, (CASE WHEN Shift-1 < 5 THEN DATEADD(Day, -1, MasterDates.[Date]) ELSE MasterDates.[Date]	END) )AS [TradingDate],
				Product,
				2,
				Quantity
		FROM DLData
		JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
		JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
		LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DLData.Product
		JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
		WHERE MasterDates.[Date] BETWEEN @From AND DATEADD( Day, 1, @To)
		AND MasterDates.[Date] >= @SiteOnline
		
		DELETE
		FROM #TradingDispensed
		WHERE NOT (TradingDate BETWEEN @From AND @To)
	END
	ELSE
	BEGIN
		INSERT INTO #TradingDispensed
		(TradingDate, ProductID, LiquidType, Quantity)
		SELECT	DATEADD(Hour, Shift-1, MasterDates.[Date])AS [TradingDate],
				Product,
				2,
				Quantity
		FROM DLData
		JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
		JOIN @SitePumpOffsets AS SitePumpOffsets ON SitePumpOffsets.EDISID = MasterDates.EDISID
		LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = DLData.Product
		JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND MasterDates.[Date] >= @SiteOnline		
	END		
END

-- Get deliveries for period
IF @UseTradingDays = 1
BEGIN
	INSERT INTO #TradingDelivered
	(TradingDate, ProductID, Quantity)
	SELECT DATEADD(hour, 11, [Date]) AS [TradingDate],
		ISNULL(PrimaryProducts.PrimaryProductID, Delivery.Product) AS ProductID,
		Quantity
	FROM Delivery
	JOIN MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Delivery.Product
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	WHERE MasterDates.[Date] BETWEEN @From AND DATEADD(Day, 1, @To)
	AND MasterDates.[Date] >= @SiteOnline

	DELETE
	FROM #TradingDelivered
	WHERE NOT (TradingDate BETWEEN @From AND @To)
END
ELSE
BEGIN
	INSERT INTO #TradingDelivered
	(TradingDate, ProductID, Quantity)
	SELECT [Date] AS [TradingDate],
		ISNULL(PrimaryProducts.PrimaryProductID, Delivery.Product) AS ProductID,
		Quantity
	FROM Delivery
	JOIN MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
	LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Delivery.Product
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	WHERE MasterDates.[Date] BETWEEN @From AND @To
	AND MasterDates.[Date] >= @SiteOnline
END

-- All beer dispensed (hourly)
INSERT INTO @BeerDispensed
(TradingDate, ProductID, Quantity)
SELECT  DATEADD(minute, -DATEPART(minute, TradingDate), DATEADD(second, -DATEPART(second, TradingDate), TradingDate)),
		ProductID,
		SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
GROUP BY DATEADD(minute, -DATEPART(minute, TradingDate), DATEADD(second, -DATEPART(second, TradingDate), TradingDate)), ProductID

-- All deliveries (convert quality into pints from gallons) (hourly)
INSERT INTO @BeerDelivered
(TradingDate, ProductID, Quantity)
SELECT  DATEADD(minute, -DATEPART(minute, TradingDate), DATEADD(second, -DATEPART(second, TradingDate), TradingDate)),
		ProductID, 
        SUM(Quantity) * 8
FROM #TradingDelivered AS TradingDelivered
GROUP BY DATEADD(minute, -DATEPART(minute, TradingDate), DATEADD(second, -DATEPART(second, TradingDate), TradingDate)), ProductID

/*
-- All beer dispensed (weekly)
INSERT INTO @BeerDispensed
(TradingDate, ProductID, Quantity)
SELECT  DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate),
		ProductID,
		SUM(Quantity)
FROM #TradingDispensed AS TradingDispensed
GROUP BY DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate), ProductID

-- All deliveries (convert quality into pints from gallons) (weekly)
INSERT INTO @BeerDelivered
(TradingDate, ProductID, Quantity)
SELECT  DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate),
		ProductID, 
        SUM(Quantity) * 8
FROM #TradingDelivered AS TradingDelivered
GROUP BY DATEADD(day, -DATEPART(dw, TradingDate) +1 , TradingDate), ProductID
*/

-- Calculate daily yield
SELECT COALESCE(BeerDispensed.[TradingDate], BeerDelivered.[TradingDate]) AS [TradingDate],
	Products.Description AS Product,
	Products.IsCask AS [IsCask],
	CASE WHEN Products.IsCask = 0 AND Products.IsMetric = 0 AND Products.IsWater = 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsKeg],
	Products.IsMetric AS [IsMetric],
	ISNULL(BeerDispensed.Quantity, 0) AS [Dispensed],
	ISNULL(BeerDelivered.Quantity, 0) AS [Delivered],
	ISNULL(BeerDelivered.Quantity, 0) - ISNULL(BeerDispensed.Quantity, 0) AS [Variance],
	NULL AS CumulativeStockVariance
FROM @BeerDispensed AS BeerDispensed
FULL OUTER JOIN @BeerDelivered AS BeerDelivered ON (BeerDelivered.ProductID = BeerDispensed.ProductID AND BeerDelivered.TradingDate = BeerDispensed.TradingDate)
JOIN Products ON Products.[ID] = COALESCE(BeerDispensed.ProductID, BeerDelivered.ProductID)
JOIN Configuration ON PropertyName = 'AuditDate'
WHERE (Products.IsCask = 0 OR @IncludeCasks = 1) 
  AND (Products.IsCask = 1 OR @IncludeKegs = 1) 
  AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
  AND COALESCE(BeerDispensed.[TradingDate], BeerDelivered.[TradingDate]) < DATEADD(day, -DATEPART(dw, CAST(Configuration.PropertyValue AS DATETIME)) +1, CAST(Configuration.PropertyValue AS DATETIME) + 7)
ORDER BY COALESCE(BeerDispensed.[TradingDate], BeerDelivered.[TradingDate]), Products.Description

DROP TABLE #TradingDispensed
DROP TABLE #TradingDelivered

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDeliveryVariance] TO PUBLIC
    AS [dbo];

