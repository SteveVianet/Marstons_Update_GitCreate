CREATE PROCEDURE [dbo].[GetClientEstateReport] 
AS 

DECLARE @DatabaseID INT    
SELECT @DatabaseID = ID FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases WHERE [Name]  = DB_NAME()

EXEC [EDISSQL1\SQL1].Auditing.dbo.GetAuditSites @DatabaseID, 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetClientEstateReport] TO PUBLIC
    AS [dbo];

