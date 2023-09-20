CREATE PROCEDURE dbo.[GetSitePumpLiquidByDay]
(
	@EDISID	INT,
	@PumpID	INT = NULL,
	@LiquidType	INT,
	@FromDate	DATETIME,
	@ToDate	DATETIME
)
AS
SELECT 	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)),
		Pump,
		Product AS ProductID,
		COUNT(*) AS NumberOfDrinks,
		SUM(Pints) AS NumberOfPints
FROM DispenseActions
		JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
		AND DispenseActions.EDISID = @EDISID
		AND (DispenseActions.Pump = @PumpID OR @PumpID IS NULL)
		AND DispenseActions.LiquidType = @LiquidType
		AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= Sites.SiteOnline
GROUP BY	DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)), Product, Pump
ORDER BY Pump, Product, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePumpLiquidByDay] TO PUBLIC
    AS [dbo];

