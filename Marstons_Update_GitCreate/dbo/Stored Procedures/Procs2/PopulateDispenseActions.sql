
CREATE PROCEDURE [dbo].[PopulateDispenseActions]

AS
BEGIN
	INSERT INTO DispenseActions
	SELECT ToCopy.EDISID, 
	ToCopy.Date + CONVERT(VARCHAR(10), ToCopy.StartTime, 8) AS StartTime, 
	CASE WHEN DATEPART(Hour, ToCopy.StartTime) < 5 THEN DATEADD(Day, -1, ToCopy.Date) ELSE ToCopy.Date END AS TradingDay,
	ToCopy.Pump,
	LocationID AS Location,
	ToCopy.Product,
	ToCopy.Duration,
	ToCopy.AverageTemperature,
	ToCopy.MinimumTemperature,
	ToCopy.MaximumTemperature,
	ToCopy.LiquidType,
	ToCopy.OriginalLiquidType,
	ToCopy.AverageConductivity,
	ToCopy.MinimumConductivity,
	ToCopy.MaximumConductivity,
	ToCopy.Pints,
	PintsBackup,
	dbo.fnGetSiteDrinkVolume(ToCopy.EDISID, ToCopy.Pints*100, ToCopy.Product) AS EstimatedDrinks,
	IFMLiquidType
	FROM 
		(SELECT TOP 10000 
		MasterDates.ID, 
		MasterDates.EDISID, 
		MasterDates.Date,
		DispenseConditions.StartTime,
		DispenseConditions.Pump,
		DispenseConditions.ProductID AS Product,
		DispenseConditions.Duration,
		DispenseConditions.AverageTemperature,
		DispenseConditions.MinimumTemperature,
		DispenseConditions.MaximumTemperature,
		DispenseConditions.LiquidType,
		DispenseConditions.OriginalLiquidType,
		DispenseConditions.AverageConductivity,
		DispenseConditions.MinimumConductivity,
		DispenseConditions.MaximumConductivity,
		DispenseConditions.Pints,
		NULL AS PintsBackup,
		NULL AS EstimatedDrinks,
		NULL AS IFMLiquidType
		FROM DispenseConditions
		JOIN MasterDates ON MasterDates.ID = DispenseConditions.MasterDateID
		LEFT JOIN DispenseActions ON MasterDates.EDISID = DispenseActions.EDISID AND MasterDates.Date + CONVERT(VARCHAR(10), DispenseConditions.StartTime, 8) = DispenseActions.StartTime AND DispenseConditions.Pump = DispenseActions.Pump
		WHERE DispenseActions.Pump IS NULL) AS ToCopy
	LEFT JOIN PumpSetup ON PumpSetup.Pump = ToCopy.Pump AND ToCopy.EDISID = PumpSetup.EDISID AND ToCopy.Product = PumpSetup.ProductID AND ((ToCopy.Date BETWEEN ValidFrom AND ValidTo) OR (ToCopy.Date >= ValidFrom AND ValidTo IS NULL))

END