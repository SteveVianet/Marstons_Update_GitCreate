CREATE PROCEDURE [dbo].[DeleteCallReason]
(
	@ID	INT
)

AS

DELETE FROM dbo.CallReasons
WHERE [ID] = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCallReason] TO PUBLIC
    AS [dbo];

