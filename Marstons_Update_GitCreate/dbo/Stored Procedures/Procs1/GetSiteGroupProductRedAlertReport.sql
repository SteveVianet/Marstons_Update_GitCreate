CREATE PROCEDURE GetSiteGroupProductRedAlertReport
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT = 1
)

AS

DECLARE @InternalSiteGroupID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold		TABLE([ProductID] INT NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalSiteGroupID 	 = @SiteGroupID
SET @InternalFrom 	 	= @From
SET @InternalTo 	 	= @To

-- Important note: The Granularity is ignored (but the parameter is preserved for compatibility)

SET NOCOUNT ON

DECLARE @SiteOnline SMALLDATETIME

SELECT @SiteOnline = MIN(SiteOnline)
FROM Sites
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID

INSERT INTO @Dispensed
SELECT DLData.Product AS ProductID, SUM(DLData.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = MasterDates.EDISID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= @SiteOnline
GROUP BY DLData.Product

INSERT INTO @Delivered
SELECT Delivery.Product AS ProductID, SUM(Delivery.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = MasterDates.EDISID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= @SiteOnline
GROUP BY Delivery.Product

INSERT INTO @Sold
SELECT Sales.ProductID AS ProductID, SUM(Sales.Quantity) AS Quantity
FROM MasterDates
JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = MasterDates.EDISID
WHERE SiteGroupSites.SiteGroupID = @InternalSiteGroupID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= @SiteOnline
GROUP BY Sales.ProductID

SELECT COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID) AS [ProductID],
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM @Dispensed AS Dispensed
FULL JOIN @Delivered AS Delivered ON Dispensed.[ProductID] = Delivered.[ProductID]
FULL JOIN @Sold AS Sold ON Dispensed.[ProductID] = Sold.[ProductID]
ORDER BY ProductID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupProductRedAlertReport] TO PUBLIC
    AS [dbo];

