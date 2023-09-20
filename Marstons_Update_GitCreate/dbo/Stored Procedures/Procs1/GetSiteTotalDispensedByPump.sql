

CREATE PROCEDURE GetSiteTotalDispensedByPump
(
	@EDISID		INT,
	@From		DATETIME,
	@To		DATETIME
)
AS
SELECT 	Pump, 
	SUM(Quantity) AS Quantity
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY Pump
ORDER BY Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteTotalDispensedByPump] TO PUBLIC
    AS [dbo];

