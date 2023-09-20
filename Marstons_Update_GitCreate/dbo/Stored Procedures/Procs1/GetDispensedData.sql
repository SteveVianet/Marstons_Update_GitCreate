---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDispensedData
(
	@SiteID		VARCHAR(50),
	@FromDate		DATETIME,
	@ToDate		DATETIME
)

AS

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM dbo.Sites
WHERE SiteID = @SiteID

SELECT	Products.[Description] AS Product, 
		Products.[ID], 
		SUM(Quantity) AS Quantity, 
		Products.Tied 
FROM dbo.DLData 
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Products ON DLData.Product = Products.[ID] 
WHERE MasterDates.EDISID = @EDISID 
AND MasterDates.[Date] BETWEEN @FromDate AND @ToDate
GROUP BY	Products.[Description], 
		Products.[ID], 
		Products.Tied


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispensedData] TO PUBLIC
    AS [dbo];

