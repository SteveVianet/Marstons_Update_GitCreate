CREATE PROCEDURE [dbo].[GetSiteEPOSPerPour] 
(
	@EDISID						INT,
	@From						DATETIME,
	@To							DATETIME,
	@IncludeCasks				BIT,
	@IncludeKegs				BIT,
	@IncludeMetric				BIT
)
AS

/* Based on [dbo].[GetWebSiteSales]
*/

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SitePumpCounts TABLE(Counter INT IDENTITY(1,1) PRIMARY KEY, EDISID INT NOT NULL, MaxPump INT NOT NULL)
DECLARE @SitePumpOffsets TABLE(EDISID INT NOT NULL, PumpOffset INT NOT NULL)
DECLARE @SiteOnline DATETIME

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

SELECT	Sales.EDISID,
		CAST(CAST(Sales.TradingDate AS DATE) AS DATETIME) + CAST(Sales.SaleTime AS TIME) AS TradingDateAndTime,
		PrimaryProducts2.Description AS Product,
		PrimaryProducts2.[ID] AS ProductID,
		Sales.Quantity,
		Owners.POSYieldCashValue AS CashValue
FROM Sales
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = Sales.EDISID
JOIN Sites ON Sites.EDISID = RelevantSites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN Products ON Products.[ID] = Sales.ProductID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Sales.ProductID
LEFT OUTER JOIN Products AS PrimaryProducts2 ON PrimaryProducts2.[ID] = ISNULL(PrimaryProducts.PrimaryProductID, Sales.ProductID)
WHERE (TradingDate BETWEEN @From AND @To)
AND TradingDate >= @SiteOnline
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
ORDER BY CAST(CAST(Sales.SaleDate AS DATE) AS DATETIME) + CAST(Sales.SaleTime AS TIME)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteEPOSPerPour] TO [fusion]
    AS [dbo];

