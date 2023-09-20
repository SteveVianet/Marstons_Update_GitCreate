CREATE PROCEDURE [dbo].[zRS_DurationsReport]
AS

SELECT             Configuration.PropertyValue AS PubCompany,
                   Sites.SiteID,
                   Sites.Name, 
                   Sites.SerialNo, 
                   DispenseActions.Pump, 
--                 FlowmeterConfiguration.PhysicalAddress AS IFMAddress,
--                 FlowmeterConfiguration.Version AS IFMVersion,
                   Products.Description AS Product,
                   COUNT(*) AS DispenseCount,
                   SUM(Pints) AS DispenseSum
                   
FROM DispenseActions

JOIN Configuration	ON Configuration.PropertyName	= 'Company Name'
JOIN Sites			ON Sites.EDISID					= DispenseActions.EDISID
JOIN Products		ON Products.ID					= DispenseActions.Product

--LEFT JOIN FlowmeterConfiguration ON FlowmeterConfiguration.EDISID = Sites.EDISID AND FlowmeterConfiguration.FontNumber = DispenseActions.Pump

WHERE 
		Sites.Quality = 1
		AND DispenseActions.TradingDay BETWEEN DATEADD(DD,-1, CAST (GETDATE() AS DATE))AND DATEADD(DD,-1, CAST (GETDATE() AS DATE))
		AND ( (Duration > 1000)-- AND Pints BETWEEN 1 AND 3) 
		OR (Duration > 2000 AND Pints > 50) )
		AND Products.IsMetric = 0
        AND LiquidType IN (2, 5)
  
GROUP BY         Configuration.PropertyValue,
                 Sites.SiteID,
                 Sites.Name, 
                 Sites.SerialNo, 
                 DispenseActions.Pump, 
                 --FlowmeterConfiguration.PhysicalAddress,
                 --FlowmeterConfiguration.Version,
                 Products.Description
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_DurationsReport] TO PUBLIC
    AS [dbo];

