CREATE PROCEDURE [dbo].[GetCallWorkDetailComments]
(
	@CallID	INT
)

AS

SELECT	[ID],
	WorkDetailComment,
	WorkDetailCommentBy,
	SubmittedOn,
	EditedOn,
	IsInvoice
FROM dbo.CallWorkDetailComments
WHERE CallID = @CallID
ORDER BY SubmittedOn

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallWorkDetailComments] TO PUBLIC
    AS [dbo];

