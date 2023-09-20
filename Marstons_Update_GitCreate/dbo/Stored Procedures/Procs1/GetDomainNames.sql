
CREATE PROCEDURE [dbo].[GetDomainNames]
AS

SELECT	[ID],
		[Domain]
FROM dbo.DomainNames

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDomainNames] TO PUBLIC
    AS [dbo];

