

CREATE PROCEDURE [dbo].[DeleteServiceIssueEquipment]
(
	@ID			INT
)
AS

DELETE FROM dbo.ServiceIssuesEquipment
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteServiceIssueEquipment] TO PUBLIC
    AS [dbo];

