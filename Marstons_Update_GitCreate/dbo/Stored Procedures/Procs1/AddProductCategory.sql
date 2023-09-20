CREATE PROCEDURE [dbo].[AddProductCategory]
(
	@Description	VARCHAR(50),
	@NewID		INTEGER		OUTPUT,
	@MinimumPouringYield	INTEGER = 100,
	@MaximumPouringYield	INTEGER = 100,
	@LowErrThreshold		INTEGER = 95,
	@HighErrThreshold		INTEGER = 107
)

AS

INSERT INTO dbo.ProductCategories
([Description], MinimumPouringYield, MaximumPouringYield, LowPouringYieldErrThreshold, HighPouringYieldErrThreshold)
VALUES
(@Description, @MinimumPouringYield, @MaximumPouringYield, @LowErrThreshold, @HighErrThreshold)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProductCategory] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProductCategory] TO [ProductCreator]
    AS [dbo];

