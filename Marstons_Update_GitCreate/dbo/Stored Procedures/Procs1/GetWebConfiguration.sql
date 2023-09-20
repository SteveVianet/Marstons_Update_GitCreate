CREATE PROCEDURE [dbo].[GetWebConfiguration]

AS

SELECT	EDIS.ShowApproxVarianceStock AS ShowWebStockVariance,
		EDIS.ShowWebMetricVariance,
		EDIS.ShowWebREDValue
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS EDIS
JOIN Configuration ON Configuration.PropertyName = 'Service Owner ID'
WHERE EDIS.Name = DB_NAME()
  AND EDIS.ID = Configuration.PropertyValue

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebConfiguration] TO PUBLIC
    AS [dbo];

