CREATE PROCEDURE GetCallFaultSLAs
AS

SELECT FaultTypeID,
	 SLA
FROM CallFaultSLAs

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallFaultSLAs] TO PUBLIC
    AS [dbo];

