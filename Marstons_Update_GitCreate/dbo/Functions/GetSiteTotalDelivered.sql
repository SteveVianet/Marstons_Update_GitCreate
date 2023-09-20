CREATE FUNCTION [dbo].[GetSiteTotalDelivered]
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
	DECLARE @SiteOnline DATETIME

	SELECT @SiteOnline = SiteOnline
	FROM dbo.Sites
	WHERE EDISID = @EDISID

	SELECT @TotalVolume = COALESCE(SUM(Quantity),0)
	FROM Delivery
	JOIN MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
	JOIN Products ON Products.[ID] = Delivery.Product
	LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND Products.[ID] = SiteProductTies.ProductID
	LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
	WHERE MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @From AND @To
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
    ON OBJECT::[dbo].[GetSiteTotalDelivered] TO PUBLIC
    AS [dbo];

