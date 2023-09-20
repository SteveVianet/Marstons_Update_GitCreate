CREATE PROCEDURE dbo.UpdateSiteAlert 
(
	@EDISID		INTEGER,
	@AlertID		INTEGER,
	@Acknowledged	BIT,
	@Comment		VARCHAR(8000),
	@ClearedDate		DATETIME,
	@Resolved       BIT = 0
)
AS

UPDATE dbo.AlertHistory
SET Acknowledged = @Acknowledged, AlertComment = @Comment, AlertDateCleared = @ClearedDate, Resolved = @Resolved
WHERE [ID] = @AlertID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteAlert] TO PUBLIC
    AS [dbo];

