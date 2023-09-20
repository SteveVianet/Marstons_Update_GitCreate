---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetTotalProductDispensed
(
	@EDISID		INT,
	@ProductID	INT,
	@From		DATETIME,
	@To		DATETIME
)

AS

DECLARE @InternalEDISID		INT
DECLARE @InternalProductID	INT
DECLARE @InternalFrom		DATETIME
DECLARE @InternalTo		DATETIME

SET @InternalEDISID	= @EDISID
SET @InternalProductID	= @ProductID
SET @InternalFrom	= @From
SET @InternalTo		= @To

SELECT SUM(Quantity) AS TotalDispensed
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON MasterDates.EDISID = Sites.EDISID
WHERE Sites.EDISID = @InternalEDISID
AND DLData.Product = @InternalProductID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTotalProductDispensed] TO PUBLIC
    AS [dbo];

