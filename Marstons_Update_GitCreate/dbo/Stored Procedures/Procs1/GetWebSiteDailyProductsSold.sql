

CREATE PROCEDURE [dbo].[GetWebSiteDailyProductsSold]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT = 1,
	@IncludeKegs	BIT = 1,
	@IncludeMetric	BIT = 0
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteOnline  DATETIME

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL)

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @EDISID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
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

-- Unroll ProductGroups so we can work out how to transform ProductIDs to their primaries
INSERT INTO @PrimaryProducts
(ProductID, PrimaryProductID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

SELECT TradingDate, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID) AS ProductID, Products.[Description], SUM(Quantity) AS Volume
FROM Sales
JOIN Products ON Products.ID = Sales.ProductID
JOIN @Sites AS RelevantSites ON RelevantSites.[EDISID] = Sales.[EDISID]
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sales.ProductID
WHERE TradingDate BETWEEN @From AND @To
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Products.IsWater = 0)
GROUP BY TradingDate, ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID), Products.[Description]
ORDER BY TradingDate, Products.[Description]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteDailyProductsSold] TO PUBLIC
    AS [dbo];

