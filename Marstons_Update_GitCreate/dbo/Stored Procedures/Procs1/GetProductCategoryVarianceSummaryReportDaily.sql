CREATE PROCEDURE dbo.GetProductCategoryVarianceSummaryReportDaily

	@EDISID 	INT,
	@CategoryID 	INT,
	@From		DATETIME,
	@To		DATETIME

AS

DECLARE @InternalEDISID 	INT
DECLARE @InternalCategoryID	INT
DECLARE @InternalFrom 	SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)

DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT

SET @InternalEDISID 		= @EDISID
SET @InternalCategoryID	= @CategoryID
SET @InternalFrom 	 	= @From
SET @InternalTo 	 	= @To

SET NOCOUNT ON
SET DATEFIRST 1


-- Look for site group. Get other EDISIDs
INSERT INTO @Sites
(EDISID)
SELECT @InternalEDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @InternalEDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @InternalEDISID

--Now we have any site group info in @Sites
--Get variance figures for the category
INSERT INTO @Dispensed
SELECT	MasterDates.[Date],
	SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN Products ON DLData.Product = Products.ID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.CategoryID = @InternalCategoryID
GROUP BY MasterDates.[Date]

INSERT INTO @Delivered
SELECT	MasterDates.[Date],
	SUM(Delivery.Quantity) AS Delivered
FROM MasterDates
JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN Products ON Delivery.Product = Products.ID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.CategoryID = @InternalCategoryID
GROUP BY MasterDates.[Date]

INSERT INTO @Sold
SELECT	MasterDates.[Date],
	SUM(Sales.Quantity) AS Sold
FROM MasterDates
JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Sales.ProductID = Products.ID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Products.CategoryID = @InternalCategoryID
GROUP BY MasterDates.[Date]

SELECT COALESCE(Dispensed.[Date], Delivered.[Date], Sold.[Date]) AS [Date],
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM @Dispensed AS Dispensed
FULL JOIN @Delivered AS Delivered	ON Dispensed.[Date] = Delivered.[Date]
FULL JOIN @Sold AS Sold 		ON (Dispensed.[Date] = Sold.[Date] OR Delivered.[Date] = Sold.[Date])

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductCategoryVarianceSummaryReportDaily] TO PUBLIC
    AS [dbo];

