CREATE PROCEDURE [dbo].[GetSystemTypeAgeMatrix]
(
	@ContractID		INT = NULL
)
AS

SELECT	SystemTypes.[ID],
		SystemTypes.Description AS SystemType,
		SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 1 THEN 1 ELSE 0 END) AS LessThan1Year,
	   SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 1 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 2 THEN 1 ELSE 0 END) AS Between1And2Years,
		SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 2 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 3 THEN 1 ELSE 0 END) AS Between2And3Years,
		SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 3 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 4 THEN 1 ELSE 0 END)AS Between3And4Years,
		SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 4 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 5 THEN 1 ELSE 0 END) AS Between4And5Years,
	   SUM(CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 5 OR dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) IS NULL THEN 1 ELSE 0 END) AS MoreThan5Years
FROM Sites
JOIN SystemTypes ON SystemTypes.ID = Sites.SystemTypeID
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
WHERE Hidden = 0 
AND (ContractID = @ContractID OR @ContractID IS NULL)
GROUP BY SystemTypes.[ID], SystemTypes.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemTypeAgeMatrix] TO PUBLIC
    AS [dbo];

