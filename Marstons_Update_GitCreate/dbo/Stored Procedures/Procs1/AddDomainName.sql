CREATE PROCEDURE [dbo].[AddDomainName]
(
	@Domain	VARCHAR(255)
)

AS

INSERT INTO dbo.DomainNames
(Domain)
VALUES
(@Domain)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDomainName] TO PUBLIC
    AS [dbo];

