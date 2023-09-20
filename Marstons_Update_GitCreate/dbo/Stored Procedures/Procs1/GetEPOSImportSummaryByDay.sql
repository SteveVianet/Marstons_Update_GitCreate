
CREATE PROCEDURE [dbo].[GetEPOSImportSummaryByDay]
(
	@From	DATE,
	@To		DATE
)

AS

SELECT  Configuration.PropertyValue AS CompanyName,
		Owners.Name AS SubCompanyName,
		Sites.SiteID,
		Sites.Name,
		Sites.PostCode,
		Sales.TradingDate AS TradingDate,
		SUM(Sales.Quantity) AS QuantityUKPints,
		SUM(Sales.Quantity)*19.2152 AS QuantityUSFlOz
FROM Sales
JOIN Sites ON Sites.EDISID = Sales.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Sales.TradingDate BETWEEN @From AND @To
GROUP BY Configuration.PropertyValue,
		 Owners.Name,
		 Sites.SiteID,
		 Sites.Name,
		 Sites.PostCode,
		 Sales.TradingDate
ORDER BY Configuration.PropertyValue,
		 Owners.Name,
		 Sites.PostCode,
		 Sites.SiteID,
		 Sites.Name,
		 Sales.TradingDate


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEPOSImportSummaryByDay] TO PUBLIC
    AS [dbo];

