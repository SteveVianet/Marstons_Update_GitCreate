CREATE PROCEDURE [dbo].[GetAuditorDailyDispense] 
	
	@EDISID INT,
	@TradingDay DATETIME
	
AS
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #DailyDispense(TradingDateAndTime DATETIME, Pump INTEGER, Product VARCHAR(50), Pints FLOAT)

	INSERT INTO #DailyDispense(TradingDateAndTime, Pump, Product, Pints)
	SELECT CAST(DATEADD(dd, 0, DATEDIFF(dd, 0, TradingDay)) + CONVERT(VARCHAR(10), StartTime, 108) AS DATETIME) AS TradingDateAndTime,
		Pump,
		Products.Description,
		Pints
	FROM DispenseActions
	JOIN Products ON Products.[ID] = DispenseActions.Product
	WHERE DispenseActions.EDISID = @EDISID 
	AND DispenseActions.TradingDay = @TradingDay 

	SELECT TradingDateAndTime,
			Pump,
			Product,
			Pints
	FROM #DailyDispense
	ORDER BY Pump ASC
	DROP TABLE #DailyDispense

END
