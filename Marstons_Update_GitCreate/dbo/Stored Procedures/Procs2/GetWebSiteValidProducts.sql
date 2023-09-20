CREATE PROCEDURE [dbo].[GetWebSiteValidProducts]
(
	@EDISID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@IncludeCasks	BIT,
	@IncludeKegs	BIT,
	@IncludeMetric	BIT
)

AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteOnline  DATETIME

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL, ProductName VARCHAR(50) NOT NULL)

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
(ProductID, PrimaryProductID, ProductName)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID, ProductGroupPrimaries.PrimaryProductName
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
	SELECT ProductGroupID, ProductID AS PrimaryProductID, Products.[Description] AS PrimaryProductName
	FROM ProductGroupProducts
	JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
	JOIN Products ON Products.ID = ProductGroupProducts.ProductID
	WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 AND IsPrimary = 0

SELECT ISNULL(PrimaryProducts.PrimaryProductID, Products.ID) AS ID, ISNULL(PrimaryProducts.ProductName, Products.[Description]) AS Product
FROM PumpSetup
JOIN @Sites AS RelevantSites ON RelevantSites.EDISID = PumpSetup.EDISID
JOIN Products ON Products.ID = PumpSetup.ProductID
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.ID
WHERE (ValidFrom <= @To)
AND	(ISNULL(ValidTo, @To) >= @From)
AND (ISNULL(ValidTo, @To) >= @SiteOnline)
AND (Products.IsCask = 0 OR @IncludeCasks = 1)
AND (Products.IsCask = 1 OR @IncludeKegs = 1)
AND (Products.IsMetric = 0 OR @IncludeMetric = 1)
AND (Products.IsWater = 0)
GROUP BY ISNULL(PrimaryProducts.PrimaryProductID, Products.ID), ISNULL(PrimaryProducts.ProductName, Products.[Description])
ORDER BY ISNULL(PrimaryProducts.ProductName, Products.[Description])
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteValidProducts] TO PUBLIC
    AS [dbo];

