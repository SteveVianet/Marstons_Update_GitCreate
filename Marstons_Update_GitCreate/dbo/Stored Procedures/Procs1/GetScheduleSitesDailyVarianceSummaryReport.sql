CREATE PROCEDURE dbo.GetScheduleSitesDailyVarianceSummaryReport
(
	@ScheduleID 	INT,
	@From 	SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

DECLARE @InternalScheduleID 	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE([WeekDay] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered			TABLE([WeekDay] INT NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold			TABLE([WeekDay] INT NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalScheduleID = @ScheduleID
SET @InternalFrom = @From
SET @InternalTo = @To

SET NOCOUNT ON

SET DATEFIRST 1

INSERT INTO @Dispensed
SELECT DATEPART(dw, MasterDates.[Date]) AS [WeekDay], SUM(DLData.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = DLData.Product
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
AND Products.IsWater = 0
GROUP BY DATEPART(dw, MasterDates.[Date])

INSERT INTO @Delivered
SELECT DATEPART(dw, MasterDates.[Date]) AS [WeekDay], SUM(Delivery.Quantity) AS Quantity
FROM dbo.MasterDates
JOIN dbo.Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = Delivery.Product
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
AND Products.IsWater = 0
GROUP BY DATEPART(dw, MasterDates.[Date])

INSERT INTO @Sold
SELECT DATEPART(dw, MasterDates.[Date]) AS [WeekDay], SUM(Sales.Quantity) AS Sold
FROM dbo.MasterDates
JOIN dbo.Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = Sites.EDISID
JOIN dbo.Products ON Products.[ID] = Sales.ProductID
WHERE ScheduleSites.ScheduleID = @InternalScheduleID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND MasterDates.[Date] >= Sites.SiteOnline
AND Products.IsWater = 0
GROUP BY DATEPART(dw, MasterDates.[Date])

SELECT COALESCE(Dispensed.[WeekDay], Delivered.[WeekDay], Sold.[WeekDay]) AS [WeekDay],
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM @Dispensed AS Dispensed
FULL JOIN @Delivered AS Delivered	ON Dispensed.[WeekDay] = Delivered.[WeekDay]
FULL JOIN @Sold AS Sold 		ON (Dispensed.[WeekDay] = Sold.[WeekDay] OR Delivered.[WeekDay] = Sold.[WeekDay])
ORDER BY [WeekDay]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetScheduleSitesDailyVarianceSummaryReport] TO PUBLIC
    AS [dbo];

