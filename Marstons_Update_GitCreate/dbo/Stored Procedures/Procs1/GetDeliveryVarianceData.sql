---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDeliveryVarianceData
(
	@SiteID	VARCHAR(50),
	@StartDate 	DATETIME,
	@EndDate 	DATETIME
)

AS

DECLARE @EDISID		INT
DECLARE @DateProducts	TABLE(DateProductsDate DATETIME, DateProductsProduct INT)
DECLARE @Dispensed		TABLE(DispensedDate DATETIME, DispensedProduct INT, DispensedQuantity FLOAT)
DECLARE @Delivered		TABLE(DeliveredDate DATETIME, DeliveredProduct INT, DeliveredQuantity FLOAT)

SET NOCOUNT ON

SELECT 	@EDISID = EDISID
FROM		Sites
WHERE	SiteID = @SiteID

SET DATEFIRST 1

INSERT INTO	@DateProducts
SELECT	Dates.[Date], 
		Products.Product 
FROM 		dbo.fnDates(@StartDate, @EndDate) AS Dates
CROSS JOIN 	dbo.fnProducts(@StartDate, @EndDate, @EDISID) AS Products

INSERT INTO	@Dispensed
SELECT	[Date], 
		Product,
		Quantity
FROM		dbo.fnDeliveryVarianceDispensed(@StartDate, @EndDate, @EDISID)

INSERT INTO	@Delivered
SELECT	[Date], 
		Product,
		Quantity
FROM		dbo.fnDeliveryVarianceDelivered(@StartDate, @EndDate, @EDISID)

SELECT	Products.[Description] AS Product, 
		DateProductsDate AS [Date],
		ISNULL(SUM(DeliveredQuantity), 0) AS Delivered,
		ISNULL(SUM(DispensedQuantity), 0) AS Dispensed,
		ISNULL(SUM(DeliveredQuantity), 0) - ISNULL(SUM(DispensedQuantity), 0) AS Variance
FROM 		@DateProducts
LEFT OUTER JOIN @Delivered
	ON (DeliveredDate = DateProductsDate
	AND DeliveredProduct = DateProductsProduct)
LEFT OUTER JOIN @Dispensed
	ON DispensedDate = DateProductsDate
	AND DispensedProduct = DateProductsProduct
INNER JOIN dbo.Products
	ON Products.[ID] = DateProductsProduct
GROUP BY Products.[Description], DateProductsDate
ORDER BY Products.[Description], DateProductsDate


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveryVarianceData] TO PUBLIC
    AS [dbo];

