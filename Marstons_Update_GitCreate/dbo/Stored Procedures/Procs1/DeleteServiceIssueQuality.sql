CREATE PROCEDURE [dbo].[DeleteServiceIssueQuality]
(
	@ID			INT
)
AS

SET NOCOUNT ON

DELETE FROM dbo.ServiceIssuesQuality
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteServiceIssueQuality] TO PUBLIC
    AS [dbo];

