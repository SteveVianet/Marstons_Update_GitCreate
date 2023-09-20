---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetWaterDispensedBySite
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME
)

AS

--Get water data
SELECT	MasterDates.[Date],
	SUM(DLData.Quantity) AS Quantity
FROM MasterDates
JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
JOIN Products ON Products.[ID] = DLData.Product
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
AND Products.IsWater = 1
GROUP BY MasterDates.[Date]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterDispensedBySite] TO PUBLIC
    AS [dbo];

