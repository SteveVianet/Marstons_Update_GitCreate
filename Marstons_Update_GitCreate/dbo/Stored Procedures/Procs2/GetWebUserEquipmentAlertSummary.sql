CREATE PROCEDURE [dbo].[GetWebUserEquipmentAlertSummary]
(
	@UserID		INT,
	@From		DATETIME,
	@To			DATETIME
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @DatabaseID INT
DECLARE @AllSites BIT
DECLARE @UserName VARCHAR(50)

CREATE TABLE #EquipmentAlerts(EDISID INT, [Date] DATETIME, EquipmentInputID INT)

SELECT @AllSites = AllSitesVisible, @UserName = UserName FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO #EquipmentAlerts
EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetCustomerAlerts @DatabaseID, @From, @To

;WITH PrimarySites AS (
SELECT Sites.EDISID, PrimaryEDISID
FROM Sites
LEFT JOIN 
	(
	SELECT PrimarySites.SiteGroupID, PrimaryEDISID, EDISID
	FROM (
		SELECT EDISID AS PrimaryEDISID, SiteGroupID
		FROM SiteGroupSites 
		JOIN SiteGroups 
		  ON SiteGroups.ID = SiteGroupSites.SiteGroupID
		WHERE IsPrimary = 1
		  AND TypeID = 1) AS PrimarySites
	JOIN (
		SELECT EDISID, SiteGroupID
		FROM SiteGroupSites 
		JOIN SiteGroups 
		  ON SiteGroups.ID = SiteGroupSites.SiteGroupID
		WHERE IsPrimary = 0
		  AND TypeID = 1) AS NonPrimarySites
	  ON NonPrimarySites.SiteGroupID = PrimarySites.SiteGroupID
	) AS PrimaryIDs
ON PrimaryIDs.PrimaryEDISID = Sites.EDISID)
SELECT 
	COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentItems.EDISID) AS EDISID,
	COUNT(InputID) AS EquipmentOnSite,
	ISNULL(Alerts.EquipmentWithAlerts, 0) AS EquipmentWithAlerts
FROM 
	EquipmentItems
JOIN PrimarySites ON PrimarySites.EDISID = EquipmentItems.EDISID
LEFT JOIN (
	SELECT 
		EDISID,
		COUNT(DISTINCT(EquipmentInputID)) AS EquipmentWithAlerts
	FROM 
		#EquipmentAlerts
	GROUP BY 
		EDISID
	) AS Alerts ON Alerts.EDISID = EquipmentItems.EDISID
WHERE
	EquipmentItems.InUse = 1
AND
	(COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentItems.EDISID) IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR (@AllSites = 1))
GROUP BY 
	COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentItems.EDISID), ISNULL(Alerts.EquipmentWithAlerts, 0)
ORDER BY
	COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentItems.EDISID)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserEquipmentAlertSummary] TO PUBLIC
    AS [dbo];

