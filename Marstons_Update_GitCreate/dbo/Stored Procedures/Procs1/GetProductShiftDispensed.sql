---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetProductShiftDispensed
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME
)

AS

SELECT DLData.Product,
	DLData.Shift, 
	SUM(DLData.Quantity) AS Quantity
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY DLData.Product, DLData.Shift


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductShiftDispensed] TO PUBLIC
    AS [dbo];

