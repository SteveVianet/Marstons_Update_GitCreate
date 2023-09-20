CREATE PROCEDURE dbo.GetSitesSystemAges
AS

SELECT	EDISID,
		InstallationDate,
		SystemTypes.[Description] AS SystemType
FROM Sites
JOIN SystemTypes ON SystemTypes.ID = Sites.SystemTypeID
WHERE Sites.Hidden = 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesSystemAges] TO PUBLIC
    AS [dbo];

