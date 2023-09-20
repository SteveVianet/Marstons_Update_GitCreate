CREATE PROCEDURE [dbo].[UpdateSiteProductCategorySpecification]
	@EDISID					INT,
	@ProductCategoryID		INT,
	@MinimumPouringYield	INT = 100,
	@MaximumPouringYield	INT = 100,
	@LowErrThreshold		INT = 95,
	@HighErrThreshold		INT = 107
AS

UPDATE SiteProductCategorySpecifications
SET MinimumPouringYield = @MinimumPouringYield,
	MaximumPouringYield = @MaximumPouringYield,
	LowPouringYieldErrThreshold = @LowErrThreshold,
	HighPouringYieldErrThreshold = @HighErrThreshold
	
WHERE EDISID = @EDISID
  AND ProductCategoryID = @ProductCategoryID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProductCategorySpecification] TO PUBLIC
    AS [dbo];

