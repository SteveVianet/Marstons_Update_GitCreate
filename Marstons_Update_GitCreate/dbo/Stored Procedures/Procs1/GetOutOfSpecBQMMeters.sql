CREATE PROCEDURE dbo.[GetOutOfSpecBQMMeters]
(
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

SELECT DispenseActions.EDISID,
	  DispenseActions.Pump,
               StartTime AS DispenseDate,
	  DispenseActions.MinimumTemperature,
	  DispenseActions.AverageTemperature
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN DATEADD(day, -1, @From) AND @To
AND Sites.Quality = 1
AND Sites.Hidden = 0
AND Sites.SiteClosed = 0
AND (DispenseActions.MinimumTemperature < 2
OR DispenseActions.AverageTemperature > 30)
AND StartTime BETWEEN @From AND @To
ORDER BY DispenseActions.EDISID, DispenseActions.Pump, StartTime

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutOfSpecBQMMeters] TO PUBLIC
    AS [dbo];

