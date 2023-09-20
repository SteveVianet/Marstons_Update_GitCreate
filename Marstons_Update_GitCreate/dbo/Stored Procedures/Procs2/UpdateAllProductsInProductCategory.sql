CREATE PROCEDURE [dbo].[UpdateAllProductsInProductCategory]
(
	@CategoryID	INT,

	@Price				MONEY = NULL,
	@Tied				BIT = NULL,
	@IsWater			BIT = NULL,
	@IsCask			BIT = NULL,
	@TemperatureSpecification	REAL = NULL,
	@TemperatureTolerance	REAL = NULL,
	@FlowRateSpecification	REAL = NULL,
	@FlowRateTolerance		REAL = NULL,
	@IsMetric			BIT = NULL,
	@LineCleanDaysBeforeAmber	INT = NULL,
	@LineCleanDaysBeforeRed	INT = NULL,
	@OwnerID INT = NULL,
	@DistributorID INT = NULL
)

AS

IF @Price IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	Price = @Price
WHERE CategoryID = @CategoryID
END

IF @Tied IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	Tied = @Tied
WHERE CategoryID = @CategoryID
END

IF @IsWater IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	IsWater = @IsWater
WHERE CategoryID = @CategoryID
END

IF @TemperatureSpecification IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	TemperatureSpecification = @TemperatureSpecification
WHERE CategoryID = @CategoryID
END

IF @TemperatureTolerance IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	TemperatureTolerance = @TemperatureTolerance
WHERE CategoryID = @CategoryID
END

IF @FlowRateSpecification IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	FlowRateSpecification = @FlowRateSpecification
WHERE CategoryID = @CategoryID
END

IF @FlowRateTolerance IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	FlowRateTolerance = @FlowRateTolerance
WHERE CategoryID = @CategoryID
END

IF @IsMetric IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	IsMetric = @IsMetric
WHERE CategoryID = @CategoryID
END

IF @LineCleanDaysBeforeAmber IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	LineCleanDaysBeforeAmber = @LineCleanDaysBeforeAmber
WHERE CategoryID = @CategoryID
END

IF @LineCleanDaysBeforeRed IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	LineCleanDaysBeforeRed = @LineCleanDaysBeforeRed
WHERE CategoryID = @CategoryID
END

IF @OwnerID IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	OwnerID = @OwnerID
WHERE CategoryID = @CategoryID
END

IF @DistributorID IS NOT NULL 
BEGIN
UPDATE dbo.Products
SET	DistributorID = @DistributorID
WHERE CategoryID = @CategoryID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateAllProductsInProductCategory] TO PUBLIC
    AS [dbo];

