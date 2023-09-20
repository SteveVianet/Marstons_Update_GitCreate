CREATE PROCEDURE GetSiteGroupCaskVarianceSummaryReport
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT
)

-- N.B. Granularity parameter is ignored - always assumed to be 1 (weekly)

AS

DECLARE @InternalSiteGroupID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME

SET @InternalSiteGroupID = @SiteGroupID
SET @InternalFrom = @From
SET @InternalTo = @To

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @DispensedData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @DeliveredData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @SoldData TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @PrimaryEDISID INT

-- Find primary site for product tie configuration
SELECT @PrimaryEDISID = EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @InternalSiteGroupID AND IsPrimary = 1

--Get dispensed data
INSERT INTO @DispensedData
([Date], Quantity)
SELECT 	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(DLData.Quantity) AS Dispensed
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = DLData.[Product]
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @PrimaryEDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @PrimaryEDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND Products.IsCask = 1
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

--Get delivered data
INSERT INTO @DeliveredData
([Date], Quantity)
SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Delivery.Quantity) AS Delivered
FROM dbo.MasterDates
JOIN dbo.Delivery WITH (INDEX (IX_Delivery_DeliveryID_Product)) ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = Delivery.[Product]
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @PrimaryEDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @PrimaryEDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND Products.IsCask = 1
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

--Get sold data
INSERT INTO @SoldData
([Date], Quantity)
SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Sales.Quantity) AS Sold
FROM dbo.MasterDates
JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = Sales.[ProductID]
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @PrimaryEDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @PrimaryEDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND Products.IsCask = 1
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

--Return data
SELECT COALESCE(DispensedData.[Date], DeliveredData.[Date], SoldData.[Date]) AS [Date],
	ISNULL(DispensedData.Quantity, 0) AS Dispensed,
	ISNULL(DeliveredData.Quantity, 0) AS Delivered,
	ISNULL(SoldData.Quantity, 0) AS Sold
FROM @DispensedData AS DispensedData
FULL JOIN @DeliveredData AS DeliveredData ON DispensedData.[Date] = DeliveredData.[Date]
FULL JOIN @SoldData AS SoldData ON DispensedData.[Date] = SoldData.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupCaskVarianceSummaryReport] TO PUBLIC
    AS [dbo];

