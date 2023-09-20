CREATE PROCEDURE [dbo].[GetCommunicationProviders] 
AS

SELECT	[ID],
	[ProviderName]
FROM dbo.CommunicationProviders

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCommunicationProviders] TO PUBLIC
    AS [dbo];

