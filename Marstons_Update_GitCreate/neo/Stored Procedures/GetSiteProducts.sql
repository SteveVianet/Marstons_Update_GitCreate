CREATE PROCEDURE [neo].[GetSiteProducts]
(
	@UserID	INT,
	@From DATETIME,
    @To DATETIME
)

AS
BEGIN
SET NOCOUNT ON

-- Get MultiCellar Sites
DECLARE @Sites TABLE 
(
	EDISID INT
)

INSERT INTO @Sites
SELECT EDISID
FROM dbo.fnGetMultiCellarSites(@UserID, NULL, NULL)

CREATE TABLE #Products (
	[ID] INT NOT NULL, 
	[Name] VARCHAR(255)
	)

INSERT INTO #Products ([ID])
SELECT DISTINCT Product
FROM dbo.DispenseActions AS DispenseActions
JOIN @Sites AS s ON s.EDISID = DispenseActions.EDISID
WHERE TradingDay BETWEEN @From AND @To
--UNION
--SELECT DISTINCT Product
--FROM dbo.Delivery AS Delivery
--JOIN dbo.MasterDates AS MasterDates 
--  ON MasterDates.ID = Delivery.DeliveryID
--JOIN @Sites AS s ON s.EDISID = MasterDates.EDISID
--UNION
--SELECT DISTINCT Product 
--FROM dbo.DLData AS DLData
--JOIN dbo.MasterDates AS MasterDates 
--  ON MasterDates.ID = DLData.DownloadID
--JOIN @Sites AS s ON s.EDISID = MasterDates.EDISID
--UNION
--SELECT DISTINCT ProductID
--FROM dbo.Stock AS Stock
--JOIN dbo.MasterDates AS MasterDates 
--  ON MasterDates.ID = Stock.MasterDateID
--JOIN @Sites AS s ON s.EDISID = MasterDates.EDISID
UNION
SELECT DISTINCT ProductID
FROM dbo.Sales AS Sales
JOIN @Sites AS s ON s.EDISID = Sales.EDISID
WHERE TradingDate BETWEEN @From AND @To
UNION
SELECT DISTINCT ProductID
FROM dbo.PumpSetup AS PumpSetup
JOIN @Sites AS s ON s.EDISID = PumpSetup.EDISID
WHERE (ValidTo IS NOT NULL AND ValidFrom < @To AND ValidTo > @From)  OR  (ValidTo IS NULL AND ValidFrom < @To)
--UNION
--SELECT DISTINCT ProductID
--FROM dbo.SiteProductTies AS SiteProductTies
--JOIN @Sites AS s ON s.EDISID = SiteProductTies.EDISID

SELECT #Products.[ID] AS ProductID, 
	p.[Description] AS [ProductName], 
	pc.ID AS CategoryID,
	pc.Description AS CategoryName
FROM #Products 
JOIN Products AS p
	ON p.ID = #Products.ID
JOIN ProductCategories AS pc
	ON pc.ID = p.CategoryID
ORDER BY pc.Description

DROP TABLE #Products
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSiteProducts] TO PUBLIC
    AS [dbo];

