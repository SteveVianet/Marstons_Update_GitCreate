CREATE PROCEDURE dbo.GetScheduleSitesProductRedAlertReport
(
	@ScheduleID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

DECLARE @InternalScheduleID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE(ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE(ProductID INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold		TABLE(ProductID INT NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalScheduleID	= @ScheduleID
SET @InternalFrom 	 	= @From
SET @InternalTo 	 	= @To

SET NOCOUNT ON

INSERT INTO @Dispensed
SELECT DLData.Product AS ProductID, SUM(DLData.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.ScheduleSites ON MasterDates.EDISID = ScheduleSites.EDISID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY DLData.Product

INSERT INTO @Delivered
SELECT Delivery.Product AS ProductID, SUM(Delivery.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.ScheduleSites ON MasterDates.EDISID = ScheduleSites.EDISID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY Delivery.Product

INSERT INTO @Sold
SELECT Sales.ProductID, SUM(Sales.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.ScheduleSites ON MasterDates.EDISID = ScheduleSites.EDISID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY Sales.ProductID

SELECT Products.ID AS ProductID,
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM @Dispensed AS Dispensed
FULL JOIN @Delivered AS Delivered ON Dispensed.[ProductID] = Delivered.[ProductID]
FULL JOIN @Sold AS Sold ON (Dispensed.[ProductID] = Sold.[ProductID] OR Delivered.[ProductID] = Sold.[ProductID])
JOIN dbo.Products ON Products.[ID] = COALESCE(Dispensed.ProductID, Delivered.ProductID, Sold.ProductID)
WHERE Products.IsWater = 0 
ORDER BY Products.ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetScheduleSitesProductRedAlertReport] TO PUBLIC
    AS [dbo];

