---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetIssueCategories

AS

SELECT	[ID],
		[Description],
		[Urgent]
FROM IssueCategories


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetIssueCategories] TO PUBLIC
    AS [dbo];

