CREATE PROCEDURE [dbo].[GetAuditorMeterDataIssues]
AS

SET NOCOUNT ON

DECLARE @From DATETIME
DECLARE @To DATETIME
DECLARE @From1WeekBack DATETIME

SET @To = GETDATE()
SET @From = DATEADD(day, -1, @To)
SET @From1WeekBack = DATEADD(day, -6, @To)

DECLARE @MeterDataIssues TABLE(EDISID INT NOT NULL, Pump INT NOT NULL, Product VARCHAR(50) NOT NULL, Value FLOAT NOT NULL, IsUnknown BIT NOT NULL)

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @MeterDataIssues
(EDISID, Pump, Product, Value, IsUnknown)
SELECT EDISID, Pump, Products.[Description], MAX(AverageTemperature), 0
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
WHERE StartTime BETWEEN @From AND @To
AND AverageTemperature NOT BETWEEN -0.5 AND 30
AND Products.IsMetric = 0
AND DispenseActions.Pints >= 0.05
GROUP BY EDISID, Pump, Products.[Description]

INSERT INTO @MeterDataIssues
(EDISID, Pump, Product, Value, IsUnknown)
SELECT EDISID, Pump, Products.[Description], SUM(Pints), 1
FROM DispenseActions
JOIN Products ON Products.[ID] = DispenseActions.Product
WHERE StartTime BETWEEN @From1WeekBack AND @To
AND LiquidType = 0
GROUP BY EDISID, Pump, Products.[Description]
HAVING SUM(Pints) > 10

SELECT @CustomerID AS Customer,
	   MeterDataIssues.EDISID,
	   CASE WHEN OpenCalls.[ID] IS NULL THEN NULL ELSE dbo.GetCallReference(OpenCalls.[ID]) END AS 
CallRef,
	   MeterDataIssues.Pump,
	   MeterDataIssues.Product,
	   MeterDataIssues.Value,
	   MeterDataIssues.IsUnknown
FROM @MeterDataIssues AS MeterDataIssues
LEFT JOIN (	SELECT Calls.EDISID, Calls.[ID], MAX(CallStatusHistory.StatusID) AS Status
			FROM Calls
			JOIN @MeterDataIssues AS MeterDataIssues ON MeterDataIssues.EDISID = Calls.EDISID
			JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID] AND 
CallStatusHistory.StatusID <> 6
			GROUP BY Calls.EDISID, Calls.[ID]
			HAVING MAX(CallStatusHistory.StatusID) NOT IN (4, 5) 
		  ) AS OpenCalls ON OpenCalls.EDISID = MeterDataIssues.EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorMeterDataIssues] TO PUBLIC
    AS [dbo];

