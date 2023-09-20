---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetDailyShiftDispensed]
(
	@EDISID		INT,
	@From		DATETIME,
	@To		DATETIME,
	@ProductID	INTEGER	= NULL,
	@OnlyHolidays BIT = 0
)

AS

SELECT MasterDates.[Date], 
	DLData.Shift,
	SUM(Quantity) AS Quantity
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
AND (@ProductID IS NULL OR DLData.Product = @ProductID)
AND (@OnlyHolidays = 0 OR MasterDates.[Date] IN (SELECT [Date] FROM Holidays))
GROUP BY MasterDates.[Date], DLData.Shift


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDailyShiftDispensed] TO PUBLIC
    AS [dbo];

