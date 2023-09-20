CREATE PROCEDURE [neo].[GetYieldQuality] 
	(@EDISID INT,
    @UserID INT,
    @From DATE,
    @To DATE)

AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @LineCleaning TABLE (
		EDISID INT NOT NULL, ChildProdID INT, ProductID INT NOT NULL,
		Description VARCHAR(1000), Product VARCHAR(1000) NOT NULL, CleanState INT NOT NULL,
		Dispense FLOAT NOT NULL, UncleanDispense FLOAT NOT NULL)

	DECLARE @DispenseQuality TABLE (
		Pump INT, ChildProductID INT, ProductID INT, Products VARCHAR(1000),
		[Location] VARCHAR(50), Quantity FLOAT,
		QuantityInSpec FLOAT, QuantityInAmber FLOAT, QuantityOutOfSpec FLOAT, TemperatureStatus INT, AverageFlowRate FLOAT, 
		FlowRateSpecification INT, FlowRateTolerance INT, TemperatureSpecification INT, TemperatureTolerance INT, AverageTemperature FLOAT)

	DECLARE @YieldQuality TABLE (ProductID INT NOT NULL, Products VARCHAR(1000) NOT NULL, TemperatureStatus INT NOT NULL, CleanState INT NOT NULL)
	
	INSERT INTO @LineCleaning 
	EXEC [neo].[GetUserLineCleaningSummary] @UserID, @From, @To;

	INSERT INTO @DispenseQuality
	EXEC [neo].[GetSiteDispenseQuality] @EDISID, @From, @To;

	INSERT INTO @YieldQuality
	SELECT DISTINCT dq.ProductID, dq.Products, dq.TemperatureStatus,lc.CleanState 
	FROM @DispenseQuality AS dq
	LEFT JOIN @LineCleaning AS lc ON  dq.ProductID = lc.ProductID

	SELECT DISTINCT
		ProductID,
		Products,
		MAX(TemperatureStatus) OVER(PARTITION  BY ProductID) AS TemperatureStatus,
		MAX(CleanState) OVER(PARTITION  BY ProductID) AS CleanState
	
	FROM @YieldQuality
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetYieldQuality] TO PUBLIC
    AS [dbo];

