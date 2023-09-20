CREATE PROCEDURE [dbo].[GetCallRequests]
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCallRequests

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallRequests] TO PUBLIC
    AS [dbo];

