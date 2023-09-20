CREATE PROCEDURE [dbo].[AddAutomatedQualitySiteRankings]
(
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

DECLARE curDatabases CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT Sites.EDISID, Sites.LastDownload
FROM Sites
LEFT JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
LEFT JOIN SiteGroups ON SiteGroups.[ID] = SiteGroupSites.SiteGroupID AND TypeID = 1
WHERE Quality = 1
AND Hidden = 0
AND (IsPrimary = 1 OR IsPrimary IS NULL)
--AND LastDownload >= DATEADD(day, -1, GETDATE())
ORDER BY Sites.EDISID

DECLARE @EDISID			INT
DECLARE @LastDownload		DATETIME
DECLARE @PreviousWeek		DATETIME

OPEN curDatabases
FETCH NEXT FROM curDatabases INTO @EDISID, @LastDownload

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @PreviousWeek = DATEADD(week, -1, @LastDownload)

	EXEC AddAutomatedTemperatureSiteRanking @EDISID, @From, @To
	EXEC AddAutomatedFlowrateSiteRanking @EDISID, @From, @To
	EXEC AddAutomatedEquipmentSiteRanking @EDISID, @From, @To
	EXEC AddAutomatedCleaningSiteRanking @EDISID, @From, @To
	EXEC AddAutomatedYieldSiteRanking @EDISID, @From, @To

	FETCH NEXT FROM curDatabases INTO @EDISID, @LastDownload
END

CLOSE curDatabases
DEALLOCATE curDatabases

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutomatedQualitySiteRankings] TO PUBLIC
    AS [dbo];

