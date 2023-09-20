
CREATE PROCEDURE [dbo].[DeleteServiceIssueYield]
(
	@ID			INT
)
AS

DELETE FROM dbo.ServiceIssuesYield
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteServiceIssueYield] TO PUBLIC
    AS [dbo];

