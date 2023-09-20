CREATE PROCEDURE [dbo].[GetServiceIssuesEquipment]
(
	@CallID					INTEGER
)

AS

SELECT ID,
	   EDISID,
	   CallID,
	   InputID,
	   DateFrom,
	   DateTo
FROM ServiceIssuesEquipment
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetServiceIssuesEquipment] TO PUBLIC
    AS [dbo];

