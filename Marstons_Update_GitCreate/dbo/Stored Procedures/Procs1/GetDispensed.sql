---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDispensed
(
	@EDISID	INTEGER,
	@Date			DATETIME
)

AS

SELECT	DLData.Pump,
		DLData.Shift,
		DLData.Quantity,
		DLData.Amended,
		Products.[Description] AS Product,
		Products.[ID] AS ProductID
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.[ID] = DLData.Product
WHERE MasterDates.[Date] = @Date
AND MasterDates.EDISID = @EDISID
ORDER BY MasterDates.[Date]


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispensed] TO PUBLIC
    AS [dbo];

