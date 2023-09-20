CREATE PROCEDURE [dbo].[AddProduct]
(
	@Description			VARCHAR(50),
	@Price				MONEY,
	@Tied				BIT,
	@IsWater			BIT,
	@IsCask			BIT = 0,
	@ID				INTEGER		OUTPUT,
	@TemperatureSpecification	REAL = NULL,
	@TemperatureTolerance	REAL = NULL,
	@FlowRateSpecification	REAL = NULL,
	@FlowRateTolerance		REAL = NULL,
	@IsMetric			BIT = 0,
	@LineCleanDaysBeforeAmber	INT = 8,
	@LineCleanDaysBeforeRed	INT = 11,
	@MixRatio			INT = 0,
	@GlobalID			INT = 0,
	@DistributorID		INT = 1,
	@Purchasable		BIT = 1,
	@IsGuestAle			BIT = 0
)

AS

INSERT INTO dbo.Products
([Description], Price, Tied, IsWater, IsCask, TemperatureSpecification, TemperatureTolerance, FlowRateSpecification, FlowRateTolerance, IsMetric, LineCleanDaysBeforeAmber, LineCleanDaysBeforeRed, MixRatio, GlobalID, DistributorID, Purchasable, IsGuestAle)
VALUES
(@Description, @Price, @Tied, @IsWater, @IsCask, @TemperatureSpecification, @TemperatureTolerance, @FlowRateSpecification, @FlowRateTolerance, @IsMetric, @LineCleanDaysBeforeAmber, @LineCleanDaysBeforeRed, @MixRatio, @GlobalID, @DistributorID, @Purchasable, @IsGuestAle)

SET @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProduct] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProduct] TO [ProductCreator]
    AS [dbo];

