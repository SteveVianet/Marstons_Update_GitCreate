CREATE PROCEDURE [dbo].[GetDeliveredData2]
(
	@EDISID		VARCHAR(50),
	@FromDate		DATETIME,
	@ToDate		DATETIME
)

AS
BEGIN

DECLARE @Sites TABLE (
    EDISID INT
)
 
 -- Multi-cellar
INSERT INTO @Sites
SELECT COALESCE(sgs2.EDISID, s.EDISID) AS EDISID
FROM Sites AS s
LEFT JOIN (
    SELECT SiteGroupID, EDISID
    FROM SiteGroupSites AS s    
    LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
    WHERE sg.TypeID = 1
) AS sgs
ON sgs.EDISID = s.EDISID
LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID
WHERE s.EDISID = @EDISID

SELECT	Products.[Description] AS Product, 
		Products.[ID] AS ProductID, 
		SUM(Delivery.Quantity) AS Quantity, 
		Products.Tied 
FROM dbo.Delivery
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Products ON Delivery.Product = Products.[ID] 
JOIN @Sites AS s ON s.EDISID = MasterDates.EDISID
WHERE	MasterDates.[Date] BETWEEN @FromDate AND @ToDate
GROUP BY Products.[Description], Products.[ID], Products.Tied

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveredData2] TO PUBLIC
    AS [dbo];

