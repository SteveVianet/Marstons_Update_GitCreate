CREATE PROCEDURE [dbo].[GetServiceIssuesQuality]
(
	@CallID					INTEGER
)

AS

SELECT ID,
	   RealEDISID AS EDISID,
	   CallID,
	   RealPumpID AS PumpID,
	   ProductID,
	   PrimaryProductID,
	   DateFrom,
	   DateTo
FROM ServiceIssuesQuality
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetServiceIssuesQuality] TO PUBLIC
    AS [dbo];

