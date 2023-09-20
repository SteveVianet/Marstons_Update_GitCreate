CREATE PROCEDURE [dbo].[UpdateProductCategoryValues]
(
	@ProductCategoryID	INT,
	@ProductDescription VARCHAR(100) = NULL,
	@MinimumPouringYield	INT = NULL,
	@MaximumPouringYield	INT = NULL,
	@LowErrThreshold		INT = 95,
	@HighErrThreshold		INT = 107
)

AS

UPDATE dbo.ProductCategories
SET	MinimumPouringYield = ISNULL(@MinimumPouringYield, 100),
	MaximumPouringYield = ISNULL(@MaximumPouringYield, 100),
	LowPouringYieldErrThreshold = @LowErrThreshold,
	HighPouringYieldErrThreshold = @HighErrThreshold
WHERE [ID] = @ProductCategoryID

--MODIFIED FOR BACKWARDS COMPATIBILITY
IF @ProductDescription IS NOT NULL
BEGIN
	UPDATE dbo.ProductCategories
	SET	[Description] = @ProductDescription
	WHERE [ID] = @ProductCategoryID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductCategoryValues] TO PUBLIC
    AS [dbo];

