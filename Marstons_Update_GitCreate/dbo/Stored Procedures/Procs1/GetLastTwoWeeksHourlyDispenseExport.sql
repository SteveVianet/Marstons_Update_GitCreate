CREATE PROCEDURE [dbo].[GetLastTwoWeeksHourlyDispenseExport]
AS

DECLARE @ThisMonday DATETIME
DECLARE @WeekFrom DATETIME
DECLARE @WeekTo DATETIME
DECLARE @DayTo DATETIME
DECLARE @Sites TABLE(EDISID INT NOT NULL, SiteID VARCHAR(25) NOT NULL)
DECLARE @ClientProducts TABLE(Alias VARCHAR(25) PRIMARY KEY, ProductID VARCHAR(255))

SET NOCOUNT ON
SET DATEFIRST 1

SET @ThisMonday = DATEADD(dd, -1, DATEADD(dd, -DATEPART(dw, CONVERT(CHAR(10), GETDATE(), 120))+2, CONVERT(CHAR(10), GETDATE(), 120)))
SET @WeekTo = DATEADD(Week, -1, @ThisMonday)
SET @DayTo = DATEADD(Day, 6, @WeekTo)
SET @WeekFrom = DATEADD(Week, -1, @WeekTo) --Last 2 weeks of audited data

INSERT INTO @Sites
SELECT EDISID, 
	 SiteID 
FROM GreeneKing.dbo.Sites 
WHERE Hidden = 0

INSERT INTO @ClientProducts
(Alias, ProductID)
SELECT MIN(Alias),
       ProductID
FROM GreeneKing.dbo.ProductAlias
GROUP BY ProductID

SELECT	Sites.SiteID AS SiteCode,
	ISNULL(ClientProducts.Alias, '000000') AS Product,
	MasterDates.[Date],
	Shift-1 AS [Hour],
	DATEADD(Hour, Shift-1, MasterDates.[Date]) AS [TradingDateAndTime],
	SUM(Quantity) AS Volume
FROM GreeneKing.dbo.DLData AS DLData
JOIN GreeneKing.dbo.MasterDates AS MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN @Sites AS Sites ON Sites.EDISID = MasterDates.EDISID
FULL JOIN @ClientProducts AS ClientProducts ON ClientProducts.ProductID = DLData.Product
WHERE MasterDates.[Date] BETWEEN @WeekFrom AND @DayTo
GROUP BY Sites.SiteID,
	ISNULL(ClientProducts.Alias, '000000'),
	MasterDates.[Date],
	Shift-1,
	DATEADD(Hour, Shift-1, MasterDates.[Date])
ORDER BY Sites.SiteID,
	MasterDates.[Date],
	Shift-1,
	DATEADD(Hour, Shift-1, MasterDates.[Date])
