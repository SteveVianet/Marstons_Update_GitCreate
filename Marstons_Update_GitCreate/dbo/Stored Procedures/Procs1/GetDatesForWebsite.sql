CREATE PROCEDURE GetDatesForWebsite
(
	@From 	DATETIME,
	@To	DATETIME
)

AS

DECLARE @Date DATETIME

SET @Date = DATEADD(d,6,(SELECT PropertyValue FROM Configuration WHERE Configuration.PropertyName = 'AuditDate'))

SELECT	CONVERT(VARCHAR(10),[Date], 20) as [Date]
FROM MasterDates
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] <= @Date
GROUP BY [Date]

