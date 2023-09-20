---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ViewIssue
(
	@IssueID	INT
)

AS

UPDATE dbo.Issues
SET Viewed = 1,
	ViewedOn = GETDATE(),
	ViewedBy = SYSTEM_USER
WHERE [ID] = @IssueID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ViewIssue] TO PUBLIC
    AS [dbo];

