CREATE PROCEDURE [dbo].[GetProducts2]

	@IncludeCask	BIT = 1,
	@IncludeWater	BIT = 1,
	@IncludeMetric	BIT = 1,
	@ID		INT = NULL

AS

SET NOCOUNT ON

DECLARE @PrimaryProducts TABLE(ProductID INT NOT NULL, PrimaryProductID INT NOT NULL, GroupID INT NOT NULL)

INSERT INTO @PrimaryProducts
(ProductID, PrimaryProductID, GroupID)
SELECT ProductID, ProductGroupPrimaries.PrimaryProductID, ProductGroups.ID
FROM ProductGroupProducts
JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
JOIN (
      SELECT ProductGroupID, ProductID AS PrimaryProductID
      FROM ProductGroupProducts
      JOIN ProductGroups ON ProductGroups.ID = ProductGroupProducts.ProductGroupID
      WHERE TypeID = 1 AND IsPrimary = 1
) AS ProductGroupPrimaries ON ProductGroupPrimaries.ProductGroupID = ProductGroups.ID
WHERE TypeID = 1 --AND IsPrimary = 0

SELECT	Products.[ID] AS ProductID,
	Products.[Description] AS Product,
	Products.Price,
	Products.Tied,
	Products.IsWater,
	Products.IsCask,
	Products.ImageID,
	Products.IsMetric,
	Products.IconID,
	Products.CategoryID,
	Products.TemperatureSpecification,
	Products.TemperatureTolerance,
	Products.FlowRateSpecification,
	Products.FlowRateTolerance,
	Products.LineCleanDaysBeforeAmber,
	Products.LineCleanDaysBeforeRed,
	Products.MixRatio,
	Products.GlobalID,
	Products.DistributorID,
	CAST(CASE WHEN Products.[ID] = PrimaryProducts.PrimaryProductID THEN 1 ELSE 0 END AS BIT) AS IsPrimaryInGroup,
	CAST(CASE WHEN Products.[ID] = PrimaryProducts.PrimaryProductID OR PrimaryProducts.PrimaryProductID IS NULL THEN 1 ELSE 0 END AS BIT) AS IsPrimaryOrNotInGroup,
	ProductGroups.ID AS GroupID,
	ProductGroups.Description AS GroupDescription,
	Products.Purchasable,
	Products.IsGuestAle,
	Products.OwnerID
FROM dbo.Products
LEFT OUTER JOIN @PrimaryProducts AS PrimaryProducts ON PrimaryProducts.ProductID = Products.[ID]
LEFT OUTER JOIN ProductGroups ON ProductGroups.ID = PrimaryProducts.GroupID
WHERE (IsCask = @IncludeCask OR @IncludeCask = 1)
AND (IsWater = @IncludeWater OR @IncludeWater = 1)
AND (IsMetric = @IncludeMetric OR @IncludeMetric = 1)
AND (Products.ID = @ID OR @ID IS NULL)
ORDER BY UPPER(Products.[Description])

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProducts2] TO PUBLIC
    AS [dbo];

