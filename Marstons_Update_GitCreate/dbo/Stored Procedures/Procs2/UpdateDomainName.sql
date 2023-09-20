
CREATE PROCEDURE [dbo].[UpdateDomainName]
(
	@ID		INTEGER,
	@Domain	VARCHAR(255)
)
AS

UPDATE dbo.DomainNames
SET Domain = @Domain
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateDomainName] TO PUBLIC
    AS [dbo];

