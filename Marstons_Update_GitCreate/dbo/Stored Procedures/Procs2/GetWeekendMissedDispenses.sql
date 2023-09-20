CREATE PROCEDURE dbo.GetWeekendMissedDispenses
(
	@EDISID		INT,
	@From		DATETIME,
	@To		DATETIME,
	@ExcludeCasks	BIT = 1,
	@ExcludeWater	BIT = 1
)

AS

SET DATEFIRST 1

SET NOCOUNT ON

DECLARE @DailyProductDispensed TABLE(	WeekNumber INT, 
						DayOfWeek INT, 
						ProductID INT)

-- Get unique list of products dispensed days
INSERT INTO @DailyProductDispensed (WeekNumber, DayOfWeek, ProductID)
SELECT	DATEPART(wk, MasterDates.[Date]) AS WeekNumber, 
	DATEPART(dw, MasterDates.[Date]) AS DayOfWeek, 
	DLData.Product 
FROM MasterDates
JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
JOIN Products ON Products.[ID] = DLData.Product
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.EDISID = @EDISID
AND (Products.IsCask = 0 OR @ExcludeCasks = 0)
AND (Products.IsWater = 0 OR @ExcludeWater = 0)
GROUP BY DATEPART(wk, MasterDates.[Date]), DATEPART(dw, MasterDates.[Date]),DLData.Product

--Get count of missed weekend dispenses
SELECT COUNT(*) AS MissedWeekendProducts
FROM @DailyProductDispensed AS DuringWeek
WHERE DayOfWeek IN (7, 1, 2, 3)
AND NOT EXISTS	(SELECT * 
		FROM @DailyProductDispensed AS Weekend
		WHERE DayOfWeek IN (4, 5, 6)
		AND Weekend.WeekNumber = DuringWeek.WeekNumber
		AND DuringWeek.ProductID = Weekend.ProductID)
GROUP BY WeekNumber, ProductID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWeekendMissedDispenses] TO PUBLIC
    AS [dbo];

