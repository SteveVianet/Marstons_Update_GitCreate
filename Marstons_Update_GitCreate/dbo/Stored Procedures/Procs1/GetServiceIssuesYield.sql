CREATE PROCEDURE [dbo].[GetServiceIssuesYield]
(
	@CallID					INTEGER
)

AS

SELECT ID,
	   RealEDISID AS EDISID,
	   CallID,
	   ProductID,
	   PrimaryProductID,
	   DateFrom,
	   DateTo
FROM ServiceIssuesYield
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetServiceIssuesYield] TO PUBLIC
    AS [dbo];

