CREATE PROCEDURE [dbo].[GetDailyProductShiftDispensed]
(
	@EDISID		INT,
	@From			DATETIME,
	@To			DATETIME,
	@IncludeMultiCellars	BIT = 0,
	@Tied		BIT = NULL
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

IF @IncludeMultiCellars = 1
BEGIN
	SELECT @SiteGroupID = SiteGroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND EDISID = @EDISID
	
	INSERT INTO @Sites
	(EDISID)
	SELECT EDISID
	FROM SiteGroupSites
	WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID
END

-- Now run the query we want!
SELECT MasterDates.[Date],
	DLData.Product,
	DLData.Shift, 
	SUM(DLData.Quantity) AS Quantity
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = @EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = @EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND (COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = @Tied OR @Tied IS NULL)
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY MasterDates.[Date], DLData.Product, DLData.Shift
ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDailyProductShiftDispensed] TO PUBLIC
    AS [dbo];

