
CREATE FUNCTION [dbo].[GetSiteTotalDispense]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @TotalVolume FLOAT
	DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
	DECLARE @SiteGroupID INT
	DECLARE @SiteOnline DATETIME

	SELECT @SiteOnline = SiteOnline
	FROM dbo.Sites
	WHERE EDISID = @EDISID

	INSERT INTO @Sites
	(EDISID)
	SELECT @EDISID AS EDISID

	SELECT @SiteGroupID = SiteGroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND EDISID = @EDISID

	INSERT INTO @Sites
	(EDISID)
	SELECT EDISID
	FROM SiteGroupSites
	WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

	SELECT @TotalVolume = COALESCE(SUM(Quantity)/8.0,0)
	FROM DLData
	JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
	JOIN Products ON Products.[ID] = DLData.Product
	JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = MasterDates.EDISID
	LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
	LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
	WHERE MasterDates.[Date] BETWEEN @From AND @To
	AND MasterDates.[Date] >= @SiteOnline
	AND (Products.IsCask = 0 OR @IncludeCasks = 1)
	AND (Products.IsCask = 1 OR @IncludeKegs = 1)
	AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
	AND MasterDates.Date >= @SiteOnline
	AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1

	RETURN @TotalVolume

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTotalDispense] TO PUBLIC
    AS [dbo];

