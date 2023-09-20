CREATE PROCEDURE dbo.MI_GetProductRedAlertReport
(
	@EDISID 	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

SET NOCOUNT ON

DECLARE @SiteOnline SMALLDATETIME

SELECT @SiteOnline = SiteOnline
FROM Sites 
WHERE EDISID = @EDISID

SELECT Products.[Description] AS Product,
	ISNULL(Dispensed, 0)/8 AS Dispensed,
	ISNULL(Delivered, 0) AS Delivered,
	ISNULL(Delivered, 0)-ISNULL(Dispensed, 0)/8 AS Variance
FROM
	(SELECT	DLData.Product,
		SUM(DLData.Quantity) AS Dispensed
	FROM MasterDates
	JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
	WHERE EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @From AND @To
	AND MasterDates.[Date] >= @SiteOnline
	GROUP BY DLData.Product) AS DispensedData
FULL JOIN
	(SELECT	Delivery.Product,
		SUM(Delivery.Quantity) AS Delivered
	FROM MasterDates
	JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
	WHERE EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @From AND @To
	AND MasterDates.[Date] >= @SiteOnline
	GROUP BY Delivery.Product) AS DeliveredData
ON DispensedData.Product = DeliveredData.Product
JOIN Products ON Products.[ID] = COALESCE(DispensedData.Product, DeliveredData.Product)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MI_GetProductRedAlertReport] TO [MachineInSite]
    AS [dbo];

