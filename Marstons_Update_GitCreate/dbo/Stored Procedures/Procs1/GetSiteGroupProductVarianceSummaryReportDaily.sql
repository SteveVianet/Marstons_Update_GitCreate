CREATE PROCEDURE GetSiteGroupProductVarianceSummaryReportDaily
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@ProductID	INT,
	@Granularity	TINYINT
)

-- N.B. Granularity parameter is ignored - always assumed to be 0 (daily)

AS

DECLARE @InternalSiteGroupID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @InternalProductID	INT

SET @InternalSiteGroupID = @SiteGroupID
SET @InternalFrom = @From
SET @InternalTo = @To
SET @InternalProductID = @ProductID

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
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND DLData.Product = @InternalProductID
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
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Delivery.Product = @InternalProductID
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
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Sales.ProductID = @InternalProductID
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
    ON OBJECT::[dbo].[GetSiteGroupProductVarianceSummaryReportDaily] TO PUBLIC
    AS [dbo];

