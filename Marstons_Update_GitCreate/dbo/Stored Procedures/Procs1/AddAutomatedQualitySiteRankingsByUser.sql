CREATE PROCEDURE [dbo].[AddAutomatedQualitySiteRankingsByUser]
(
	@From				DATETIME,
	@To				DATETIME,
	@UserID			INTEGER,
	@SetTemperatureSiteRankings	BIT,
	@SetFlowrateSiteRankings	BIT,
	@SetEquipmentSiteRankings	BIT,
	@SetCleaningSiteRankings	BIT,
	@SetPouringYieldSiteRankings	BIT,
	@SetTillYieldSiteRankings	BIT
)
AS

SET NOCOUNT ON

DECLARE curDatabases CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT Sites.EDISID
FROM Sites
JOIN UserSites ON UserSites.EDISID = Sites.EDISID
LEFT JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
LEFT JOIN SiteGroups ON SiteGroups.[ID] = SiteGroupSites.SiteGroupID AND TypeID = 1
WHERE Quality = 1
AND Hidden = 0
AND (IsPrimary = 1 OR IsPrimary IS NULL)
AND UserSites.UserID = @UserID
ORDER BY Sites.EDISID

DECLARE @EDISID			INT

OPEN curDatabases
FETCH NEXT FROM curDatabases INTO @EDISID

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @SetTemperatureSiteRankings = 1
	BEGIN
		EXEC AddAutomatedTemperatureSiteRanking @EDISID, @From, @To
	END

	IF @SetFlowrateSiteRankings = 1
	BEGIN
		EXEC AddAutomatedFlowrateSiteRanking @EDISID, @From, @To
	END

	IF @SetEquipmentSiteRankings = 1
	BEGIN
		EXEC AddAutomatedEquipmentSiteRanking @EDISID, @From, @To
	END

	IF @SetCleaningSiteRankings = 1
	BEGIN
		EXEC AddAutomatedCleaningSiteRanking @EDISID, @From, @To
	END

	IF @SetPouringYieldSiteRankings = 1 OR @SetTillYieldSiteRankings = 1
	BEGIN
		EXEC AddAutomatedYieldSiteRanking @EDISID, @From, @To, @SetPouringYieldSiteRankings, @SetTillYieldSiteRankings
	END

	FETCH NEXT FROM curDatabases INTO @EDISID
END

CLOSE curDatabases
DEALLOCATE curDatabases

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutomatedQualitySiteRankingsByUser] TO PUBLIC
    AS [dbo];

