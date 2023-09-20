CREATE PROCEDURE dbo.GetOutstandingSiteBQMAlerts 
(
	@DatabaseID		INTEGER,
	@EDISID		INTEGER
)
AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.GetOutstandingSiteBQMAlerts @DatabaseID, @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutstandingSiteBQMAlerts] TO PUBLIC
    AS [dbo];

