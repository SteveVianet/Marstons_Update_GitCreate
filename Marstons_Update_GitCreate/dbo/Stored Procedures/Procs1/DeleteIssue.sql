---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteIssue
(
	@IssueID	INT
)

AS

UPDATE dbo.Issues
SET Deleted = 1,
	DeletedOn = GETDATE(),
	DeletedBy = SYSTEM_USER
WHERE [ID] = @IssueID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteIssue] TO PUBLIC
    AS [dbo];

