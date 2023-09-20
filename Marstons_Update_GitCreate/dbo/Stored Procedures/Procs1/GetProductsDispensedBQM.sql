CREATE PROCEDURE [dbo].[GetProductsDispensedBQM]
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME
)

AS

SET NOCOUNT ON

SELECT x.ProductID
FROM (
	SELECT Product AS ProductID
	FROM dbo.DispenseActions
	JOIN Sites ON DispenseActions.EDISID = Sites.EDISID
	JOIN Products ON Products.ID = DispenseActions.Product
	WHERE LiquidType = 2
	AND Pints >= 0.3
	AND DispenseActions.EDISID = @EDISID
	AND CAST(StartTime AS DATE) BETWEEN @From AND @To
	AND CAST(StartTime AS DATE) >= Sites.SiteOnline
	GROUP BY DispenseActions.Product

	UNION
	SELECT DISTINCT ProductID
	FROM dbo.PumpSetup AS PumpSetup
	WHERE EDISID = @EDISID
) AS x
JOIN Products ON Products.ID = x.ProductID
GROUP BY x.ProductID, Products.Description
ORDER BY Products.Description


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsDispensedBQM] TO PUBLIC
    AS [dbo];

