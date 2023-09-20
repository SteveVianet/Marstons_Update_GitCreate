CREATE PROCEDURE dbo.GetTotalNegativeVarianceByUserArea
(
	@UserID INT,
	@AreaID	INT,
	@From 	SMALLDATETIME,
	@To 	SMALLDATETIME
)

AS

DECLARE @InternalUserID INT
DECLARE @InternalAreaID	INT
DECLARE @InternalFrom 	SMALLDATETIME
DECLARE @InternalTo 	SMALLDATETIME

DECLARE @Dispensed TABLE(EDISID INT, Quantity FLOAT)
DECLARE @Delivered TABLE(EDISID INT, Quantity FLOAT)

SET NOCOUNT ON

SET @InternalUserID	= @UserID
SET @InternalAreaID	= @AreaID
SET @InternalFrom 	= @From
SET @InternalTo		= @To

INSERT INTO @Dispensed
(EDISID, Quantity)
SELECT	UserSites.EDISID,
 	SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN Products ON Products.[ID] = DLData.Product
LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
WHERE UserSites.UserID = @InternalUserID
AND Sites.AreaID = @InternalAreaID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY UserSites.EDISID

INSERT INTO @Delivered
(EDISID, Quantity)
SELECT	UserSites.EDISID,
 	SUM(Delivery.Quantity) AS Delivered
FROM MasterDates
JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN Products ON Products.[ID] = Delivery.Product
LEFT JOIN SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
JOIN UserSites ON UserSites.EDISID = MasterDates.EDISID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
WHERE UserSites.UserID = @InternalUserID
AND Sites.AreaID = @InternalAreaID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY UserSites.EDISID

SELECT	SUM(ISNULL(Delivered.Quantity / 0.568 * 4.546, 0)) - SUM(ISNULL(Dispensed.Quantity, 0)) AS TotalNegativeVariance
FROM @Dispensed AS Dispensed
FULL OUTER JOIN @Delivered AS Delivered
ON Dispensed.EDISID = Delivered.EDISID
WHERE ISNULL(Dispensed.Quantity, 0) > ISNULL(Delivered.Quantity / 0.568 * 4.546, 0)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalNegativeVarianceByUserArea] TO PUBLIC
    AS [dbo];

