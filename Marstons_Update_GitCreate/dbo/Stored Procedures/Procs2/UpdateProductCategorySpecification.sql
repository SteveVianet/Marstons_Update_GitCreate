CREATE PROCEDURE [dbo].[UpdateProductCategorySpecification]
(
	@ProductCategoryID		INT,
	@MinimumPouringYield	INT = NULL,
	@MaximumPouringYield	INT = NULL,
	@LowErrThreshold		INT = 95,
	@HighErrThreshold		INT = 107,
	@TargetPouringYield		INT = NULL
)

AS

IF @TargetPouringYield IS NOT NULL
BEGIN /* If Target has been supplied, only set the target */
	UPDATE dbo.ProductCategories
	SET	
		TargetPouringYield = @TargetPouringYield
	WHERE [ID] = @ProductCategoryID
END
ELSE
BEGIN /* Otherwise set everything except the target */
	UPDATE dbo.ProductCategories
	SET MinimumPouringYield = @MinimumPouringYield,
		MaximumPouringYield = @MaximumPouringYield,
		LowPouringYieldErrThreshold = @LowErrThreshold,
		HighPouringYieldErrThreshold = @HighErrThreshold
	WHERE [ID] = @ProductCategoryID
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProductCategorySpecification] TO PUBLIC
    AS [dbo];

