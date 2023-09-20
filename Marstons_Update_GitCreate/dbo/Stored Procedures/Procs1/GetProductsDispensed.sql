---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetProductsDispensed]
(
	@EDISID	INT,
	@From	DATETIME,
	@To	DATETIME
)

AS

SELECT DLData.Product AS ProductID
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON Products.ID = DLData.Product
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] BETWEEN @From AND @To
GROUP BY DLData.Product, Products.Description
ORDER BY Products.Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductsDispensed] TO PUBLIC
    AS [dbo];

