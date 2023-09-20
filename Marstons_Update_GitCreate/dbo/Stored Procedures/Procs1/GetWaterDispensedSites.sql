CREATE PROCEDURE dbo.GetWaterDispensedSites
(
	@From	DATETIME,
	@To	DATETIME
)
AS

SELECT EDISID
FROM DLData
JOIN Products ON Products.[ID] = DLData.Product
JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
WHERE Products.IsWater = 1
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterDispensedSites] TO PUBLIC
    AS [dbo];

