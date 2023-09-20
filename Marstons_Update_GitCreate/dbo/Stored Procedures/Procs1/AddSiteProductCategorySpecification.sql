CREATE PROCEDURE [dbo].[AddSiteProductCategorySpecification]
	@EDISID					INT,
	@ProductCategoryID		INT,
	@MinimumPouringYield	INT = 100,
	@MaximumPouringYield	INT = 100,
	@LowErrThreshold		INT = 95,
	@HighErrThreshold		INT = 107
AS

INSERT INTO SiteProductCategorySpecifications
	(EDISID, ProductCategoryID, MinimumPouringYield, MaximumPouringYield, LowPouringYieldErrThreshold, HighPouringYieldErrThreshold)
VALUES
	(@EDISID, @ProductCategoryID, @MinimumPouringYield, @MaximumPouringYield, @LowErrThreshold, @HighErrThreshold) 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteProductCategorySpecification] TO PUBLIC
    AS [dbo];

