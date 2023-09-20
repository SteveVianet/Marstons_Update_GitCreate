CREATE PROCEDURE dbo.GetSiteGroupDispensed
(
	@SiteGroupID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Tied		BIT
)

AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT NOT NULL, EDISID INT NOT NULL, [Date] DATETIME NOT NULL)

INSERT INTO @MasterDates
([ID], EDISID, [Date])
SELECT MasterDates.[ID], MasterDates.EDISID, [Date]
FROM MasterDates
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline

SELECT ISNULL(SUM(DLData.Quantity), 0) AS Dispensed
FROM DLData
JOIN @MasterDates AS MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupDispensed] TO PUBLIC
    AS [dbo];

