CREATE PROCEDURE [dbo].[GetVarianceSummaryReportDaily]
(
	@EDISID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	INT,
	@IncludeCasks BIT = 1,
	@IncludeKegs BIT = 1
)

AS

DECLARE @InternalEDISID 		INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME

SET @InternalEDISID = @EDISID
SET @InternalFrom = @From
SET @InternalTo = @To

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @DispensedData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @DeliveredData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @SoldData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)

--Get dispensed data
INSERT INTO @DispensedData
([Date], Quantity)
SELECT 	MasterDates.[Date] AS [Date],
	SUM(DLData.Quantity) AS Dispensed
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY MasterDates.[Date]

--Get delivered data
INSERT INTO @DeliveredData
([Date], Quantity)
SELECT	MasterDates.[Date],
	SUM(Delivery.Quantity) AS Delivered
FROM dbo.MasterDates
JOIN dbo.Delivery WITH (INDEX (IX_Delivery_DeliveryID_Product)) ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY MasterDates.[Date]

--Get sold data
INSERT INTO @SoldData
([Date], Quantity)
SELECT	MasterDates.[Date],
	SUM(Sales.Quantity) AS Sold
FROM dbo.MasterDates
JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Products ON Products.[ID] = Sales.ProductID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY MasterDates.[Date]

SELECT COALESCE(DispensedData.[Date], DeliveredData.[Date], SoldData.[Date]) AS [Date],
	ISNULL(DispensedData.Quantity, 0) AS Dispensed,
	ISNULL(DeliveredData.Quantity, 0) AS Delivered,
	ISNULL(SoldData.Quantity, 0) AS Sold
FROM @DispensedData AS DispensedData
FULL JOIN @DeliveredData AS DeliveredData ON DispensedData.[Date] = DeliveredData.[Date]
FULL JOIN @SoldData AS SoldData ON (DispensedData.[Date] = SoldData.[Date] OR DeliveredData.[Date] = SoldData.[Date])
ORDER BY COALESCE(DispensedData.[Date], DeliveredData.[Date], SoldData.[Date])

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceSummaryReportDaily] TO PUBLIC
    AS [dbo];

