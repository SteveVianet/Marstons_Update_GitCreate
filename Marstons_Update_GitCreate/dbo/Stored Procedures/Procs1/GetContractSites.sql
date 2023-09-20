CREATE PROCEDURE dbo.GetContractSites
(
	@ContractID	INT
)

AS

SELECT 	SiteContracts.EDISID,
		Sites.SiteID,
		Sites.OwnerID
FROM dbo.SiteContracts
JOIN dbo.Sites ON Sites.EDISID = SiteContracts.EDISID
WHERE SiteContracts.ContractID = @ContractID
ORDER BY [Name] ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractSites] TO PUBLIC
    AS [dbo];

