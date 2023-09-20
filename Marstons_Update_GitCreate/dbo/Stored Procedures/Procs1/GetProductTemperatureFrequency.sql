CREATE PROCEDURE dbo.[GetProductTemperatureFrequency]
(
	@ScheduleID		INT,
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@ProductID		INT = NULL
)

AS

SET NOCOUNT ON

DECLARE @InnerScheduleID INT
DECLARE @InnerFromDate DATETIME
DECLARE @InnerToDate DATETIME
DECLARE @InnerProductID INT
SET @InnerScheduleID = @ScheduleID
SET @InnerFromDate = @FromDate
SET @InnerToDate = @ToDate
SET @InnerProductID = @ProductID


SELECT Product,
	FLOOR(MinimumTemperature) AS Temperature,
	COUNT(*) AS DrinksAtThisTemperature,
	SUM(Pints) AS PintsAtThisTemperature
FROM DispenseActions
WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @InnerFromDate AND @InnerToDate
AND (Product = @InnerProductID OR @InnerProductID IS NULL)
AND Pints >= 0.3
AND LiquidType = 2
AND EDISID IN (SELECT EDISID FROM ScheduleSites WHERE ScheduleID = @InnerScheduleID)
GROUP BY FLOOR(MinimumTemperature), Product
ORDER BY Product, FLOOR(MinimumTemperature)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductTemperatureFrequency] TO PUBLIC
    AS [dbo];

