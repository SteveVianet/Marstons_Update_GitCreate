---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteGroupDelivered
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Tied		BIT
)

AS

SELECT ISNULL(SUM(Delivery.Quantity), 0) AS Delivered
FROM dbo.MasterDates
JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID
AND MasterDates.[Date] >= Sites.SiteOnline
AND MasterDates.[Date] BETWEEN @From AND @To
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupDelivered] TO PUBLIC
    AS [dbo];

