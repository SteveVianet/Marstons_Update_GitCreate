CREATE PROCEDURE dbo.GetProductVarianceSummaryReport
(
	@EDISID 	INT,
	@ProductID	INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@Granularity	TINYINT = 1
)

-- N.B. Granularity parameter is ignored (will always be weekly) but preserved for compatibility

AS

DECLARE @InternalEDISID 	INT
DECLARE @InternalProductID	INT
DECLARE @InternalFrom 		SMALLDATETIME
DECLARE @InternalTo 		SMALLDATETIME
DECLARE @Dispensed		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Delivered		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)
DECLARE @Sold		TABLE([Date] DATETIME NOT NULL, Quantity FLOAT NOT NULL)

SET @InternalEDISID 	 = @EDISID
SET @InternalProductID	 = @ProductID
SET @InternalFrom 	 = @From
SET @InternalTo 	 = @To

SET NOCOUNT ON

SET DATEFIRST 1

INSERT INTO @Dispensed
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(DLData.Quantity) AS Dispensed
FROM MasterDates
JOIN DLData ON MasterDates.[ID] = DLData.DownloadID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND DLData.Product = @InternalProductID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

INSERT INTO @Delivered
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Delivery.Quantity) AS Delivered
FROM MasterDates
JOIN Delivery ON MasterDates.[ID] = Delivery.DeliveryID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Delivery.Product = @InternalProductID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

INSERT INTO @Sold
SELECT	DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]) AS [Date],
	SUM(Sales.Quantity) AS Sold
FROM MasterDates
JOIN Sales ON MasterDates.[ID] = Sales.MasterDateID
WHERE MasterDates.EDISID = @InternalEDISID
AND MasterDates.[Date] BETWEEN @InternalFrom AND @InternalTo
AND Sales.ProductID = @InternalProductID
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

SELECT COALESCE(Dispensed.[Date], Delivered.[Date], Sold.[Date]) AS [Date],
	ISNULL(Dispensed.Quantity, 0) AS Dispensed,
	ISNULL(Delivered.Quantity, 0) AS Delivered,
	ISNULL(Sold.Quantity, 0) AS Sold
FROM @Dispensed AS Dispensed
FULL JOIN @Delivered AS Delivered	ON Dispensed.[Date] = Delivered.[Date]
FULL JOIN @Sold AS Sold 		ON (Dispensed.[Date] = Sold.[Date] OR Delivered.[Date] = Sold.[Date])


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductVarianceSummaryReport] TO PUBLIC
    AS [dbo];

