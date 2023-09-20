CREATE PROCEDURE [dbo].[MarkCallAborted]
(
	@CallID		INT,
	@AbortReasonID	INT,
	@AbortDate	DATETIME,
	@AbortUser	VARCHAR(255),
	@AbortCode	VARCHAR(255)
)

AS

SET XACT_ABORT ON

BEGIN TRAN

UPDATE dbo.Calls
SET	AbortReasonID	= @AbortReasonID,
	AbortDate	= @AbortDate,
	AbortUser	= @AbortUser,
	AbortCode	= @AbortCode
WHERE [ID] = @CallID


COMMIT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MarkCallAborted] TO PUBLIC
    AS [dbo];

