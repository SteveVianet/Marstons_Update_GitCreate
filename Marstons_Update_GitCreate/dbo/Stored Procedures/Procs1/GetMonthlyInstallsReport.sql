CREATE PROCEDURE [dbo].[GetMonthlyInstallsReport]
(
	@From	DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE @MonthsInYear TABLE([Month] DATETIME)

DECLARE @Date DATETIME
SET @Date = @From
WHILE @Date < @To
BEGIN
INSERT INTO @MonthsInYear ([Month]) VALUES (@Date)
SELECT @Date = DATEADD(MONTH, 1, @Date)
END

SELECT  MonthsInYear.[Month],
		CompletedCalls.CompletedInstalls,
		OutstandingCalls.OutstandingInstalls
FROM @MonthsInYear AS MonthsInYear
JOIN (
	SELECT  MonthsInYear.[Month],
			SUM(CASE WHEN ClosedCalls.[ID] IS NOT NULL THEN 1 ELSE 0 END) AS CompletedInstalls
	FROM @MonthsInYear AS MonthsInYear
	LEFT JOIN Calls AS ClosedCalls ON (CAST(CAST(YEAR(ClosedOn) AS VARCHAR(4)) + '/' + 
                CAST(MONTH(ClosedOn) AS VARCHAR(2)) + '/01' AS DATETIME)) = MonthsInYear.[Month] AND (ClosedCalls.CallTypeID = 2) AND (ClosedCalls.AbortReasonID = 0)
	GROUP BY MonthsInYear.[Month]
) AS CompletedCalls ON CompletedCalls.[Month] = MonthsInYear.[Month]
JOIN (
	SELECT  MonthsInYear.[Month],
			SUM(CASE WHEN OutstandingCalls.[ID] IS NOT NULL THEN 1 ELSE 0 END) AS OutstandingInstalls
	FROM @MonthsInYear AS MonthsInYear
	LEFT JOIN Calls AS OutstandingCalls ON (CAST(CAST(YEAR(RaisedOn) AS VARCHAR(4)) + '/' + 
                CAST(MONTH(RaisedOn) AS VARCHAR(2)) + '/01' AS DATETIME)) = MonthsInYear.[Month] AND (OutstandingCalls.CallTypeID = 2) AND (OutstandingCalls.AbortReasonID = 0)
	GROUP BY MonthsInYear.[Month]
) AS OutstandingCalls ON OutstandingCalls.[Month] = MonthsInYear.[Month]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMonthlyInstallsReport] TO PUBLIC
    AS [dbo];

