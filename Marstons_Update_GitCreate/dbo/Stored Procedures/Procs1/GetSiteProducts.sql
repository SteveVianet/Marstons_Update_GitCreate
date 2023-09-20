CREATE PROCEDURE [dbo].[GetSiteProducts]
(
	@EDISID	INT
)

AS

SET NOCOUNT ON

CREATE TABLE #Products ([ID] INT NOT NULL, [Name] VARCHAR(255))

INSERT INTO #Products ([ID])
SELECT DISTINCT Product
FROM dbo.DispenseActions AS DispenseActions
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT Product
FROM dbo.Delivery AS Delivery
JOIN dbo.MasterDates AS MasterDates 
  ON MasterDates.ID = Delivery.DeliveryID
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT Product 
FROM dbo.DLData AS DLData
JOIN dbo.MasterDates AS MasterDates 
  ON MasterDates.ID = DLData.DownloadID
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT ProductID
FROM dbo.Stock AS Stock
JOIN dbo.MasterDates AS MasterDates 
  ON MasterDates.ID = Stock.MasterDateID
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT ProductID
FROM dbo.Sales AS Sales
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT ProductID
FROM dbo.PumpSetup AS PumpSetup
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT ProductID
FROM dbo.SiteProductTies AS SiteProductTies
WHERE EDISID = @EDISID

UPDATE #Products
SET [Name] = Products.[Description]
FROM dbo.Products AS Products
JOIN #Products ON #Products.ID =  Products.ID

SELECT [ID], [Name] 
FROM #Products
ORDER BY [ID]

DROP TABLE #Products
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProducts] TO PUBLIC
    AS [dbo];

