---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetFlowMeterTypes

AS

SELECT [ID], [Description]
FROM dbo.FlowMeterTypes


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetFlowMeterTypes] TO PUBLIC
    AS [dbo];

