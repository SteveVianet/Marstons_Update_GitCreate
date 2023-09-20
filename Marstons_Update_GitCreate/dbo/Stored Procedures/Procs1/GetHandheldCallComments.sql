CREATE PROCEDURE dbo.GetHandheldCallComments
(
	@CallID INT
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @DatabaseID,
	   [ID] AS CallCommentID,
	   CallID,
	   SubmittedOn,
	   Comment,
	   dbo.udfNiceName(CommentBy) AS CommentBy
FROM CallComments
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHandheldCallComments] TO PUBLIC
    AS [dbo];

