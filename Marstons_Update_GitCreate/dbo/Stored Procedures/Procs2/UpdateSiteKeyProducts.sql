CREATE PROCEDURE [dbo].[UpdateSiteKeyProducts] AS

DECLARE @To		DATETIME
DECLARE @From	DATETIME

SET @To = DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0) 
SET @From = DATEADD(wk, -6, @To)

-- clear table
--DELETE FROM dbo.SiteKeyProducts
TRUNCATE TABLE dbo.SiteKeyProducts

--Key Product = Over 960 pints in 6-week period or over 10% of all site dispense for that period

-- refill it
INSERT INTO dbo.SiteKeyProducts
SELECT MasterDates.EDISID AS EDISID , DLD.Product AS ProductID
FROM dbo.MasterDates
JOIN dbo.DLData DLD ON MasterDates.[ID] = DLD.DownloadID
JOIN dbo.Products ON Products.[ID] = DLD.Product
LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND SiteProductTies.ProductID = Products.[ID]
LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
WHERE MasterDates.[Date] BETWEEN @From AND @To
AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
GROUP BY MasterDates.EDISID, DLD.Product
HAVING SUM(DLD.Quantity) > 960 OR
SUM(DLD.Quantity) > (SELECT SUM(dbo.DLData.Quantity) * .1
					 FROM dbo.MasterDates iMD
					 JOIN dbo.DLData ON iMD.[ID] = dbo.DLData.DownloadID
					 JOIN dbo.Products ON Products.[ID] = DLD.Product
					 LEFT JOIN dbo.SiteProductTies ON SiteProductTies.EDISID = MasterDates.EDISID AND SiteProductTies.ProductID = Products.[ID]
					 LEFT JOIN dbo.SiteProductCategoryTies ON SiteProductCategoryTies.EDISID = MasterDates.EDISID AND Products.CategoryID = SiteProductCategoryTies.ProductCategoryID
					 WHERE iMD.[Date] BETWEEN @From AND @To
					 AND COALESCE(SiteProductTies.Tied, SiteProductCategoryTies.Tied, Products.Tied) = 1
					 AND iMD.EDISID = MasterDates.EDISID)
ORDER BY MasterDates.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteKeyProducts] TO PUBLIC
    AS [dbo];

