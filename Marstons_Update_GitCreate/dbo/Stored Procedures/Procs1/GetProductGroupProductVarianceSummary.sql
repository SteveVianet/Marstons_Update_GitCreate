CREATE PROCEDURE [dbo].[GetProductGroupProductVarianceSummary]
(
	@EDISID 	INT,
	@ProductGroupID	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT = 1
)

-- N.B. Granularity parameter is ignored (will always be weekly) but preserved for compatibility

AS

DECLARE @InternalEDISID 	INT
DECLARE @InternalProductGroupID	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold			TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalEDISID 			= @EDISID
SET @InternalProductGroupID		= @ProductGroupID
SET @InternalFrom 				= @From
SET @InternalTo 				= @To


SET NOCOUNT ON

SET DATEFIRST 1

INSERT INTO @Dispensed
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
JOIN Products ON DLData.Product = Products.ID
JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.ID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

INSERT INTO @Delivered
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Delivery.Quantity) AS Delivered
FROM MasterDates
JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
JOIN Products ON Delivery.Product = Products.ID
JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.ID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

INSERT INTO @Sold
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Sales.Quantity) AS Sold
FROM MasterDates
JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
JOIN Products ON Sales.ProductID = Products.ID
JOIN ProductGroupProducts ON ProductGroupProducts.ProductID = Products.ID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND ProductGroupProducts.ProductGroupID = @InternalProductGroupID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

SELECT Dates.[Date],
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM (
	SELECT COALESCE(Dispensed.[Date], Delivered.[Date], Sold.[Date]) AS [Date]
	FROM @Dispensed AS Dispensed
	FULL JOIN @Delivered AS Delivered ON Dispensed.[Date] = Delivered.[Date]
	FULL JOIN @Sold AS Sold ON Dispensed.[Date] = Sold.[Date]
	GROUP BY COALESCE(Dispensed.[Date], Delivered.[Date], Sold.[Date])
) AS Dates
LEFT JOIN @Dispensed AS Dispensed ON Dispensed.[Date] = Dates.[Date]
LEFT JOIN @Delivered AS Delivered ON Delivered.[Date] = Dates.[Date]
LEFT JOIN @Sold AS Sold ON Sold.[Date] = Dates.[Date]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductGroupProductVarianceSummary] TO PUBLIC
    AS [dbo];

