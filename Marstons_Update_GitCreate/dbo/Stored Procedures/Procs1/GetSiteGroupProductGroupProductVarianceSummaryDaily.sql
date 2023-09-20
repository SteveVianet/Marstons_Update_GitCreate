
CREATE PROCEDURE dbo.GetSiteGroupProductGroupProductVarianceSummaryDaily
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@ProductGroupID	INT,
	@Granularity	TINYINT
)

-- N.B. Granularity parameter is ignored - always assumed to be 0 (daily)

AS

DECLARE @InternalSiteGroupID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @InternalProductGroupID	INT

SET @InternalSiteGroupID = @SiteGroupID
SET @InternalFrom = @From
SET @InternalTo = @To
SET @InternalProductGroupID = @ProductGroupID

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
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN dbo.Products ON dbo.DLData.Product = dbo.Products.ID
JOIN dbo.ProductGroupProducts ON dbo.ProductGroupProducts.ProductID = dbo.Products.ID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY MasterDates.[Date]

--Get delivered data
INSERT INTO @DeliveredData
([Date], Quantity)
SELECT MasterDates.[Date] AS [Date],
	SUM(Delivery.Quantity) AS Delivered
FROM dbo.MasterDates
JOIN dbo.Delivery WITH (INDEX (IX_Delivery_DeliveryID_Product)) ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN dbo.Products ON dbo.Delivery.Product = dbo.Products.ID
JOIN dbo.ProductGroupProducts ON dbo.ProductGroupProducts.ProductID = dbo.Products.ID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY MasterDates.[Date]

--Get sold data
INSERT INTO @SoldData
([Date], Quantity)
SELECT MasterDates.[Date] AS [Date],
	SUM(Sales.Quantity) AS Sold
FROM dbo.MasterDates
JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
JOIN Products ON Sales.ProductID = Products.ID
JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.ID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY MasterDates.[Date]

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
    ON OBJECT::[dbo].[GetSiteGroupProductGroupProductVarianceSummaryDaily] TO PUBLIC
    AS [dbo];

