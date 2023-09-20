CREATE PROCEDURE [dbo].[GetCallChargeReasons]
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallChargeReasons

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallChargeReasons] TO PUBLIC
    AS [dbo];

