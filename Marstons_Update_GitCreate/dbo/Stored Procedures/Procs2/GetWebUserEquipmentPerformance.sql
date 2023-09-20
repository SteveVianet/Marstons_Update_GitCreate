CREATE PROCEDURE [dbo].[GetWebUserEquipmentPerformance]
(
	@UserID		INT,
	@From		DATETIME,
	@To			DATETIME,
	@Weekly BIT = 0,
	@Overall BIT = 0
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
SELECT	Users.UserName,
		COALESCE(SiteEquipmentAlerts.[Date], WarmDispense.[Date]) AS [Date],
		SUM(CASE WHEN SiteEquipmentAlerts.CellarAlarms > 0 THEN 1 ELSE 0 END) AS SitesCellarAlarms,
		SUM(CASE WHEN SiteEquipmentAlerts.CoolerAlarms > 0 THEN 1 ELSE 0 END) AS SitesCoolerAlarms,
		WarmDispense.OutOfSpec AS PintsTooWarm
FROM
	(
	SELECT	COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentAlerts.EDISID) AS EDISID,
			CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, EquipmentAlerts.[Date]), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, EquipmentAlerts.[Date]), 0) AS DATE) END AS [Date],
			SUM(CASE WHEN EquipmentSubTypes.[Description] = 'Ambient' AND EquipmentTypes.CanRaiseAlarm = 1 THEN 1 ELSE 0 END) AS CellarAlarms,
			SUM(CASE WHEN EquipmentSubTypes.[Description] = 'Recirc' AND EquipmentTypes.CanRaiseAlarm = 1 THEN 1 ELSE 0 END) AS CoolerAlarms
	FROM #EquipmentAlerts AS EquipmentAlerts
	JOIN EquipmentItems ON EquipmentItems.EDISID = EquipmentAlerts.EDISID AND EquipmentItems.InputID = EquipmentAlerts.EquipmentInputID
	JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentItems.EquipmentTypeID
	JOIN EquipmentSubTypes ON EquipmentSubTypes.[ID] = EquipmentTypes.EquipmentSubTypeID
	JOIN PrimarySites ON PrimarySites.EDISID = EquipmentAlerts.EDISID
	WHERE (EquipmentAlerts.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR (@AllSites = 1))
	GROUP BY
		COALESCE(PrimarySites.PrimaryEDISID, PrimarySites.EDISID, EquipmentAlerts.EDISID), 
		CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, EquipmentAlerts.[Date]), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, EquipmentAlerts.[Date]), 0) AS DATE) END
	) AS SiteEquipmentAlerts
FULL OUTER JOIN
	(
	SELECT CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTemperature.[Date]), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTemperature.[Date]), 0) AS DATE) END AS [Date],
		   SUM(OutSpec) AS OutOfSpec
	FROM PeriodCacheTemperature
	JOIN ProductCategories ON PeriodCacheTemperature.CategoryID = ProductCategories.ID
	WHERE (PeriodCacheTemperature.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR @AllSites = 1)
	AND PeriodCacheTemperature.[Date] BETWEEN CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, @From), 0) AS DATE) ELSE @From END AND @To
	AND ProductCategories.IncludeInEstateReporting = 1
	GROUP BY CASE @Weekly WHEN 1 THEN CAST(DATEADD(WEEK, DATEDIFF(WEEK, 0, PeriodCacheTemperature.[Date]), 0) AS DATE) ELSE CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, PeriodCacheTemperature.[Date]), 0) AS DATE) END
	) AS WarmDispense ON WarmDispense.[Date] = SiteEquipmentAlerts.[Date]
JOIN Users ON Users.ID = @UserID
GROUP BY 
	Users.UserName, 
	COALESCE(SiteEquipmentAlerts.[Date], WarmDispense.[Date]), 
	WarmDispense.OutOfSpec
ORDER BY 
	COALESCE(SiteEquipmentAlerts.[Date], WarmDispense.[Date])

DROP TABLE #EquipmentAlerts
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserEquipmentPerformance] TO PUBLIC
    AS [dbo];

