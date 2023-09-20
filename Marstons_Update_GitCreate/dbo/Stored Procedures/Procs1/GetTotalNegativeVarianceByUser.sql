CREATE PROCEDURE dbo.GetTotalNegativeVarianceByUser
(
	@UserID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

DECLARE @InternalUserID INT
DECLARE @InternalFrom DATETIME
DECLARE @InternalTo DATETIME

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @Dispensed TABLE(EDISID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered TABLE(EDISID INT NOT NULL, Quantity FLOAT NOT NULL)

SET NOCOUNT ON

SET @InternalUserID = @UserID
SET @InternalFrom = @From
SET @InternalTo = @To

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM dbo.UserSites
WHERE UserID = @InternalUserID

-- Get dispensed
INSERT INTO @Dispensed
(EDISID, Quantity)
SELECT	Sites.EDISID,
 	SUM(DLData.Quantity)
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY Sites.EDISID

-- Get delivered
INSERT INTO @Delivered
(EDISID, Quantity)
SELECT	Sites.EDISID,
 	SUM(Delivery.Quantity) AS Delivered
FROM dbo.MasterDates
JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY Sites.EDISID


SELECT	SUM(ISNULL(Delivered.Quantity / 0.568 * 4.546, 0)) - SUM(ISNULL(Dispensed.Quantity, 0)) AS TotalNegativeVariance
FROM @Sites AS Sites
LEFT JOIN @Dispensed AS Dispensed ON Dispensed.EDISID = Sites.EDISID
LEFT JOIN @Delivered AS Delivered ON Delivered.EDISID = Sites.EDISID
WHERE ISNULL(Dispensed.Quantity, 0) > ISNULL(Delivered.Quantity / 0.568 * 4.546, 0)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalNegativeVarianceByUser] TO PUBLIC
    AS [dbo];

