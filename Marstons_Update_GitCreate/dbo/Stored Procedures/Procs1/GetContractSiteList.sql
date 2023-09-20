CREATE PROCEDURE [dbo].[GetContractSiteList]
(
	@ContractID		INT
)
AS

SELECT	Sites.EDISID,
		SiteID,
		[Name],
		COALESCE(Address3, Address4) AS Town,
		PostCode,
		ISNULL(InstallationDate, 0) AS InstallationDate
FROM dbo.SiteContracts
JOIN Sites ON Sites.EDISID = SiteContracts.EDISID
WHERE ContractID = @ContractID
ORDER BY SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractSiteList] TO PUBLIC
    AS [dbo];

