CREATE PROCEDURE [dbo].[MarkCallIncomplete]
(
	@CallID				INT,
	@IncompleteReasonID	INT,
	@IncompleteDate		DATETIME
)
AS

SET XACT_ABORT ON

BEGIN TRAN

UPDATE dbo.Calls
SET	IncompleteReasonID	= @IncompleteReasonID,
	IncompleteDate	= @IncompleteDate
WHERE [ID] = @CallID

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MarkCallIncomplete] TO PUBLIC
    AS [dbo];

