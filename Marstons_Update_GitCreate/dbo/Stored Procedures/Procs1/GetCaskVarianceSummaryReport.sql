CREATE PROCEDURE dbo.GetCaskVarianceSummaryReport
(
	@EDISID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT
)

AS

DECLARE @InternalEDISID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @InternalGranularity	TINYINT

SET @InternalEDISID = @EDISID
SET @InternalFrom = @From
SET @InternalTo = @To
SET @InternalGranularity = @Granularity

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @DispensedData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @DeliveredData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @SoldData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)

--Get dispensed data
INSERT INTO @DispensedData
([Date], Quantity)
SELECT 	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.IsCask = 1
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

--Get delivered data
INSERT INTO @DeliveredData
([Date], Quantity)
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Delivery.Quantity) AS Delivered
FROM MasterDates
JOIN Delivery WITH (INDEX (IX_Delivery_DeliveryID_Product)) ON MasterDates.[ID] = Delivery.DeliveryID
JOIN Products ON Products.[ID] = Delivery.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.IsCask = 1
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

--Get sold data
INSERT INTO @SoldData
([Date], Quantity)
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Sales.Quantity) AS Sold
FROM MasterDates
JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Products.[ID] = Sales.ProductID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.IsCask = 1
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

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
    ON OBJECT::[dbo].[GetCaskVarianceSummaryReport] TO PUBLIC
    AS [dbo];

