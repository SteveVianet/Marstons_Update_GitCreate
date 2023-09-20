---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetDeliveredData
(
	@SiteID		VARCHAR(50),
	@FromDate		DATETIME,
	@ToDate		DATETIME
)

AS

DECLARE @EDISID	INTEGER

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

SELECT	Products.[Description] AS Product, 
		Products.[ID] AS ProductID, 
		SUM(Delivery.Quantity) AS Quantity, 
		Products.Tied 
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Delivery.Product = Products.[ID] 
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = MasterDates.EDISID
WHERE	MasterDates.EDISID = @EDISID 
AND 		MasterDates.[Date] BETWEEN @FromDate AND @ToDate
GROUP BY	Products.[Description], 
		Products.[ID], 
		Products.Tied


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveredData] TO PUBLIC
    AS [dbo];

