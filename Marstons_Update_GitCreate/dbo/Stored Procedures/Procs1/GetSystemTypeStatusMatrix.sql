CREATE PROCEDURE [dbo].[GetSystemTypeStatusMatrix]
(
	@ContractID		INT = NULL
)
AS

SELECT	SystemTypes.[ID],
		SystemTypes.Description AS SystemType,
		SUM(CASE WHEN [Status] = 1 THEN 1 ELSE 0 END) AS Active,
		SUM(CASE WHEN [Status] = 2 THEN 1 ELSE 0 END) AS Closed,
		SUM(CASE WHEN [Status] = 10 THEN 1 ELSE 0 END) AS FOT,
		SUM(CASE WHEN [Status] = 3 THEN 1 ELSE 0 END) AS Legals,
		SUM(CASE WHEN [Status] = 4 THEN 1 ELSE 0 END) AS NotReportedOn,
		SUM(CASE WHEN [Status] = 5 THEN 1 ELSE 0 END) AS WrittenOff,
		SUM(CASE WHEN [Status] = 0 THEN 1 ELSE 0 END) AS Unknown
FROM Sites
JOIN SystemTypes ON SystemTypes.ID = Sites.SystemTypeID
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
WHERE Hidden = 0 
AND (ContractID = @ContractID OR @ContractID IS NULL)
GROUP BY SystemTypes.[ID], SystemTypes.[Description]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSystemTypeStatusMatrix] TO PUBLIC
    AS [dbo];

