CREATE PROCEDURE [dbo].[UpdateProduct]
(
	@ProductID			INT,
	@Description			VARCHAR(50),
	@Price				MONEY,
	@Tied				BIT,
	@IsWater			BIT,
	@IsCask			BIT = 0,
	@TemperatureSpecification	REAL = NULL,
	@TemperatureTolerance	REAL = NULL,
	@FlowRateSpecification	REAL = NULL,
	@FlowRateTolerance		REAL = NULL,
	@IsMetric			BIT = 0,
	@LineCleanDaysBeforeAmber	INT = 8,
	@LineCleanDaysBeforeRed	INT = 11,
	@MixRatio			INT = 0,
	@GlobalID			INT = 0,
	@Purchasable		BIT = 1,
	@IsGuestAle			BIT = 0,
	@OwnerID			INT = 1,
	@DistributorID		INT = 1,
	@CategoryID	INT = NULL
)

AS
IF @CategoryID IS NULL
BEGIN
UPDATE dbo.Products
SET	[Description] = @Description,
	Price = @Price,
	Tied = @Tied,
	IsWater = @IsWater,
	IsCask = @IsCask,
	TemperatureSpecification = @TemperatureSpecification,
	TemperatureTolerance = @TemperatureTolerance,
	FlowRateSpecification = @FlowRateSpecification,
	FlowRateTolerance = @FlowRateTolerance,
	IsMetric = @IsMetric,
	LineCleanDaysBeforeAmber = @LineCleanDaysBeforeAmber,
	LineCleanDaysBeforeRed = @LineCleanDaysBeforeRed,
	MixRatio = @MixRatio,
	GlobalID = @GlobalID,
	Purchasable = @Purchasable,
	IsGuestAle = @IsGuestAle,
	OwnerID = @OwnerID,
	DistributorID = @DistributorID
WHERE [ID] = @ProductID
END
ELSE
BEGIN
UPDATE dbo.Products
SET	[Description] = @Description,
	Price = @Price,
	Tied = @Tied,
	IsWater = @IsWater,
	IsCask = @IsCask,
	TemperatureSpecification = @TemperatureSpecification,
	TemperatureTolerance = @TemperatureTolerance,
	FlowRateSpecification = @FlowRateSpecification,
	FlowRateTolerance = @FlowRateTolerance,
	IsMetric = @IsMetric,
	LineCleanDaysBeforeAmber = @LineCleanDaysBeforeAmber,
	LineCleanDaysBeforeRed = @LineCleanDaysBeforeRed,
	MixRatio = @MixRatio,
	GlobalID = @GlobalID,
	Purchasable = @Purchasable,
	IsGuestAle = @IsGuestAle,
	CategoryID = @CategoryID,
	OwnerID = @OwnerID,
	DistributorID = @DistributorID
WHERE [ID] = @ProductID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateProduct] TO PUBLIC
    AS [dbo];

