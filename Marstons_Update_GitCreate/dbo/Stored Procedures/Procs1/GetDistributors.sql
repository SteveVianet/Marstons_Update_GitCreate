CREATE PROCEDURE [dbo].[GetDistributors]

AS

SELECT	[ID],
	ShortName,
	[Description]
FROM dbo.ProductDistributors
ORDER BY [Description]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDistributors] TO PUBLIC
    AS [dbo];

