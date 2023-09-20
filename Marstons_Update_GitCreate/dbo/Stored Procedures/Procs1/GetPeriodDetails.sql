
CREATE PROCEDURE dbo.GetPeriodDetails
(
	@FromWC		DATETIME
)
AS

SET NOCOUNT ON

SELECT	CurrentWeekPeriod.PeriodNumber AS CurrentWeekPeriod, 
		DATEDIFF(WEEK, CurrentWeekPeriod.FromWC, @FromWC) + 1 AS CurrentWeekNumber,
		PreviousWeekPeriod.PeriodNumber AS PreviousWeekPeriod,
		PreviousWeekPeriod.PeriodWeekNumber AS PreviousWeekNumber,
		NextWeekPeriod.PeriodNumber AS NextWeekPeriod,
		NextWeekPeriod.PeriodWeekNumber AS NextWeekNumber
FROM PubcoCalendars AS CurrentWeekPeriod
LEFT JOIN (
	SELECT	PreviousWeekPeriod.PeriodNumber, 
			DATEDIFF(WEEK, PreviousWeekPeriod.FromWC, DATEADD(WEEK, -1, @FromWC)) + 1 AS PeriodWeekNumber
	FROM PubcoCalendars AS PreviousWeekPeriod
	WHERE DATEADD(WEEK, -1, @FromWC) BETWEEN PreviousWeekPeriod.FromWC AND PreviousWeekPeriod.ToWC
) AS PreviousWeekPeriod ON 1=1
LEFT JOIN (
	SELECT	NextWeekPeriod.PeriodNumber, 
			DATEDIFF(WEEK, NextWeekPeriod.FromWC, DATEADD(WEEK, 1, @FromWC)) + 1 AS PeriodWeekNumber
	FROM PubcoCalendars AS NextWeekPeriod
	WHERE DATEADD(WEEK, 1, @FromWC) BETWEEN NextWeekPeriod.FromWC AND NextWeekPeriod.ToWC
) AS NextWeekPeriod ON 1=1
WHERE @FromWC BETWEEN CurrentWeekPeriod.FromWC AND CurrentWeekPeriod.ToWC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPeriodDetails] TO PUBLIC
    AS [dbo];

