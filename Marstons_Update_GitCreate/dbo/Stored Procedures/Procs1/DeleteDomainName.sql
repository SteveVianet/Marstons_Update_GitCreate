CREATE PROCEDURE [dbo].[DeleteDomainName]
(
	@ID		INTEGER
)
AS

DELETE 
FROM dbo.DomainNames
WHERE ID = @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDomainName] TO PUBLIC
    AS [dbo];

