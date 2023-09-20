CREATE PROCEDURE [dbo].[PeriodCacheQualityRebuild]

	@From 				DATETIME = NULL,
	@To					DATETIME = NULL

AS

DECLARE @InternalUnderSpecIsInSpec BIT
DECLARE @InternalTemperatureAmberValue FLOAT

--Err... I should perhaps have supported these!  :)
SET @InternalUnderSpecIsInSpec = 1
SET @InternalTemperatureAmberValue = 2

DELETE FROM PeriodCacheQuality
WHERE (TradingDay BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL)

--Note that site groups and pump offsets are not done here.  Why?
--Because the code which assembles 'AllSitePumps' in the normal quality sp does bad things.
--It respects ValidFrom/To depending on query results, but the normal estate reports do not.
--I think all cases of multi-cellar should ignore such dates and keep offset numbers sane.

--BUILD SPEED TABLE
INSERT INTO PeriodCacheQuality
(EDISID, TradingDay, Pump, ProductID, LocationID, Quantity, QuantityInSpec, QuantityInAmber, QuantityOutOfSpec, AverageFlowRate)
SELECT  DispenseActions.EDISID,
		TradingDay,
		Pump,
		Product,
		Location,
		SUM(Pints),
		SUM(CASE WHEN (AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) OR @InternalUnderSpecIsInSpec = 1)
			  AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) THEN Pints ELSE 0 END) AS QuantityInSpec,
		SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
			  AND AverageTemperature >= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
			  AND @InternalUnderSpecIsInSpec = 0)
			  OR (AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance)
			  AND AverageTemperature <= ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue)
			 THEN Pints ELSE 0 END) AS QuantityInAmber,
		SUM(CASE WHEN (AverageTemperature < ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) - ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) - @InternalTemperatureAmberValue
			  AND @InternalUnderSpecIsInSpec = 0)
			  OR AverageTemperature > ISNULL(SiteProductSpecifications.TempSpec, Products.TemperatureSpecification) + ISNULL(SiteProductSpecifications.TempTolerance, Products.TemperatureTolerance) + @InternalTemperatureAmberValue THEN Pints ELSE 0 END) AS QuantityOutOfSpec,
		ISNULL(AVG(Duration/dbo.fnConvertSiteDispenseVolume(DispenseActions.EDISID, Pints)),0) AS AverageFlowRate
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
LEFT JOIN SiteProductSpecifications ON SiteProductSpecifications.ProductID = DispenseActions.Product AND SiteProductSpecifications.EDISID = DispenseActions.EDISID
WHERE ((TradingDay BETWEEN @From AND @To) OR (@From IS NULL AND @To IS NULL)) AND
	  LiquidType = 2 AND
	  Pints >= 0.3 AND
	  Location IS NOT NULL
GROUP BY DispenseActions.EDISID,
		 TradingDay,
		 Pump,
		 Product,
		 Location

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheQualityRebuild] TO PUBLIC
    AS [dbo];

