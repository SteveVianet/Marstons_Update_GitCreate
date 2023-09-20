CREATE PROCEDURE dbo.GetEPOSImportSummary
AS

SELECT	Configuration.PropertyValue AS Customer,
		Sites.SiteID, 
		Sites.Name,
		Sites.PostCode,
		LatestDispense.LatestDispense, 
		LatestSales.LatestSale, 
		Sites.LastDownload, 
		DATEDIFF(DAY, LatestSales.LatestSale, LatestDispense.LatestDispense) AS DaysOut,
		CASE WHEN Sites.EPOSType = 2 THEN CAST(DATEDIFF(HOUR, LatestSales.LatestSale, LatestDispense.LatestDispense) AS VARCHAR) + ' hours' 
				ELSE CAST(DATEDIFF(Day, LatestSales.LatestSale, LatestDispense.LatestDispense) AS VARCHAR) + ' days' END AS [TimeOut],
		CASE Sites.EPOSType WHEN 0 THEN 'None'
							WHEN 1 THEN 'Auto'
							WHEN 2 THEN 'Nucleus'
							WHEN 3 THEN 'Import Manager'
							WHEN 4 THEN 'iDraught Website' END AS EPOSType
FROM (
	SELECT DispenseActions.EDISID, MAX(StartTime) AS LatestDispense
	FROM DispenseActions
	GROUP BY DispenseActions.EDISID
) AS LatestDispense
JOIN (
	SELECT EDISID, MAX(SaleDate+SaleTime) AS LatestSale
	FROM Sales
	GROUP BY EDISID
) AS LatestSales ON LatestSales.EDISID = LatestDispense.EDISID
JOIN Sites ON Sites.EDISID = LatestDispense.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE LatestSales.LatestSale > '2011-01-01' 


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEPOSImportSummary] TO PUBLIC
    AS [dbo];

