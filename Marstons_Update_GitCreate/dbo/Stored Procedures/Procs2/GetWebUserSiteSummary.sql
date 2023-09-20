


CREATE PROCEDURE [dbo].[GetWebUserSiteSummary]
(
	@UserID			INT,
	@From			DATETIME,
	@To				DATETIME
)
AS

SET NOCOUNT ON

CREATE TABLE #SiteList (Counter	INT IDENTITY(1,1) PRIMARY KEY,
						EDISID INT NOT NULL, 
						IsIDraught BIT NOT NULL, 
						SiteOnline DATE NOT NULL, 
						TiedDispense FLOAT, 
						Delivery FLOAT, 
						SiteID VARCHAR(15),
						SiteName VARCHAR(60),
						Town VARCHAR(50),
						SiteStatus INT,
						SuspectedTampering INT)
						
CREATE TABLE #SitesWithSuspectedTampering	(EDISID INT NOT NULL,
											 CaseID INT NOT NULL,
											 EventDate DATETIME NOT NULL,
											 StateID INT NOT NULL)


CREATE TABLE #SiteUsers (EDISID INT NOT NULL, UserID INT NOT NULL, UserType INT NOT NULL, LoginCount INT)
CREATE TABLE #UserLogins (UserID INT NOT NULL, LoginCount INT NOT NULL)


DECLARE @Anonymise		BIT
DECLARE @UserHasAllSites	BIT
DECLARE @UserTypeID		INTEGER

DECLARE @DatabaseID AS INT
SELECT @DatabaseID = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @CashValueOfBarrel FLOAT
SELECT @CashValueOfBarrel = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'CashValueOfBarrel'

-- Which sites are we allowed to see?
SELECT @UserHasAllSites = AllSitesVisible, @Anonymise = dbo.Users.Anonymise, @UserTypeID = UserTypes.ID
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

--Get the important site details we need so know where to get our data from
INSERT INTO #SiteList
(EDISID, IsIDraught, SiteOnline, SiteID, SiteName, Town)
SELECT Sites.EDISID, Sites.Quality AS IsIDraught, Sites.SiteOnline, Sites.SiteID, Sites.Name, ISNULL(Address3, Address4)
FROM Sites
WHERE (
		(@UserHasAllSites = 1) OR
		(Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID))
	  )
	  	
AND Sites.EDISID NOT IN (
	  SELECT EDISID
	  FROM SiteGroupSites
	  JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	  WHERE TypeID = 1 AND IsPrimary <> 1
)

AND Sites.EDISID NOT IN (
	SELECT SiteProperties.EDISID
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'Disposed Status' AND UPPER(SiteProperties.Value) = 'YES'
)
AND Sites.Hidden = 0

-- Get low volume threshold
DECLARE @LowVolumeThreshold FLOAT
SELECT @LowVolumeThreshold = MAX(Owners.ThroughputLowValue)
FROM #SiteList AS RS
JOIN Sites ON Sites.EDISID = RS.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID

-- Anonymise site details for demo purposes if we need to
UPDATE #SiteList
SET  SiteID = 'pub' + CAST(Counter AS VARCHAR),
	[SiteName] = WebDemoSites.[SiteName],
	Town = WebDemoSites.Town
FROM [SQL1\SQL1].ServiceLogger.dbo.WebDemoSites AS WebDemoSites
WHERE	@Anonymise = 1
	AND Counter = WebDemoSites.CounterID

-- If the anonymised site details list doesn't have enough entries, strip all untouched sites for privacy reasons
DELETE FROM #SiteList
WHERE SiteID NOT LIKE 'pub%' AND @Anonymise = 1


--Get tied dispense for both i-draught and dms
UPDATE #SiteList
SET 
	TiedDispense = Dispensed,
	Delivery = Delivered
FROM #SiteList
JOIN (SELECT PeriodCacheVariance.EDISID, CASE SUM(Dispensed) WHEN 0 THEN NULL ELSE SUM(Dispensed) END AS Dispensed, SUM(Delivered) AS Delivered
	  FROM #SiteList AS Sites
	  JOIN PeriodCacheVariance 
		ON PeriodCacheVariance.EDISID = Sites.EDISID 
	   AND ((PeriodCacheVariance.WeekCommencing >= Sites.SiteOnline) AND (PeriodCacheVariance.WeekCommencing BETWEEN @From AND @To))
	   AND PeriodCacheVariance.IsTied = 1
	  GROUP BY PeriodCacheVariance.EDISID) AS PCV ON PCV.EDISID = #SiteList.EDISID

UPDATE #SiteList
SET SiteStatus = Audit 
FROM SiteRankingCurrent
WHERE SiteRankingCurrent.EDISID = #SiteList.EDISID

--GET SUSPECTED TAMPERING CASES
INSERT INTO #SitesWithSuspectedTampering(EDISID, CaseID, EventDate, StateID)
	(

	SELECT	MostRecentTamperCases.EDISID,
			MostRecentTamperCases.CaseID,
			MostRecentCaseEvents.EventDate,
			TamperCaseStatuses.StateID
	FROM (
		SELECT  EDISID,
				MAX(TamperCases.CaseID) AS CaseID
		FROM TamperCases
		GROUP BY EDISID
	)AS MostRecentTamperCases
	JOIN (
		SELECT  CaseID,
				MAX(EventDate) AS EventDate
		FROM TamperCaseEvents
		GROUP BY CaseID
	) AS MostRecentCaseEvents ON MostRecentCaseEvents.CaseID = MostRecentTamperCases.CaseID
	JOIN (
		SELECT  CaseID,
				StateID,
				EventDate
		FROM TamperCaseEvents
	) AS TamperCaseStatuses ON (TamperCaseStatuses.CaseID = MostRecentTamperCases.CaseID
		AND TamperCaseStatuses.EventDate = MostRecentCaseEvents.EventDate)
	WHERE TamperCaseStatuses.StateID IN (2,5))

UPDATE #SiteList
SET SuspectedTampering = (SELECT MAX(TamperCaseEvents.SeverityID)
							FROM TamperCases
							JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
							JOIN #SitesWithSuspectedTampering ON  #SitesWithSuspectedTampering.EDISID = TamperCases.EDISID
							WHERE TamperCases.EDISID = #SiteList.EDISID
							AND TamperCaseEvents.EventDate = #SitesWithSuspectedTampering.EventDate
							GROUP BY #SitesWithSuspectedTampering.EDISID)

--BDM
INSERT INTO #SiteUsers
	(UserID, EDISID, UserType)
SELECT UserID, EDISID, 2
FROM UserSites WHERE UserID IN (SELECT ID FROM Users WHERE UserType = 2)

--RM
INSERT INTO #SiteUsers
	(UserID, EDISID, UserType)
SELECT UserID, EDISID, 1
FROM UserSites WHERE UserID IN (SELECT ID FROM Users WHERE UserType = 1)



INSERT INTO #UserLogins
(UserID, LoginCount)
SELECT UserID, COUNT(WebSessions.ID) AS Logins
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSessions
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS SessionDetails ON SessionDetails.SessionID = WebSessions.ID
WHERE WebSessions.ID IS NOT NULL AND Authenticated = 1 AND WebSiteID = 2 AND Testing = 0 AND [Enabled] = 1 AND Anonymise = 0 AND DatabaseID = @DatabaseID
AND WebSessions.[DateTime] BETWEEN @From AND @To
GROUP BY UserID


SELECT	
		RMSiteUsers.UserID AS RMID,
		RMUsers.UserName As RMName,
		ISNULL(RMLogins.LoginCount, 0) AS RMLogins,
		BDMSiteUsers.UserID AS BDMID,
		BDMUsers.UserName As BDMName,
		ISNULL(BDMLogins.LoginCount, 0) AS BDMLogins,
		SiteList.EDISID, 
		IsIDraught, 
		SiteList.SiteOnline, 
		CASE WHEN (SiteList.Delivery - SiteList.TiedDispense) < 0 THEN ((((SiteList.Delivery - SiteList.TiedDispense)/8)/ 36) * @CashValueOfBarrel) ELSE 0 END AS CashValue,
		SiteList.SiteID,
		SiteName,
		Town,
		SiteStatus,
		SuspectedTampering,
		REDValues.Value AS RedValue,
		CASE WHEN LowVolumeSites.EDISID IS NOT NULL THEN 1 ELSE 0 END AS LowVolume,
		CAST(0 AS FLOAT) AS LineCleaningPerformance,
		0 AS CleanDays,
		0 AS InToleranceDays,
		0 AS OverdueCleanDays,
		OverdueDispensePercentage,
		TotalDispense AS TotalCleanDispense,
		OverdueDispense AS OverdueCleanDispense,
		Owners.CleaningAmberPercentTarget,
		Owners.CleaningRedPercentTarget,
		Sites.SiteClosed
FROM	#SiteList AS SiteList
JOIN Sites ON Sites.EDISID = SiteList.EDISID
JOIN Owners ON Sites.OwnerID = Owners.ID
LEFT OUTER JOIN (
	SELECT EDISID, 
		   CASE WHEN SUM(TotalDispense) = 0 THEN 0 ELSE (SUM(OverdueDispense) / SUM(TotalDispense) * 100) END AS OverdueDispensePercentage,
		   TotalDispense,
		   OverdueDispense
	FROM
	(
		SELECT	EDISID,
				SUM(PeriodCacheCleaningDispense.TotalDispense) AS TotalDispense,
				SUM(PeriodCacheCleaningDispense.OverdueCleanDispense) AS OverdueDispense
		FROM PeriodCacheCleaningDispense 
		WHERE PeriodCacheCleaningDispense.[Date] BETWEEN @From AND @To
		GROUP BY EDISID
	) AS OverduePercentage
	GROUP BY EDISID, TotalDispense, OverdueDispense) AS PeriodCleaningPercentage ON PeriodCleaningPercentage.EDISID = Sites.EDISID

JOIN	#SiteUsers AS RMSiteUsers ON RMSiteUsers.EDISID = SiteList.EDISID AND RMSiteUsers.UserType = 1
JOIN	#SiteUsers AS BDMSiteUsers ON BDMSiteUsers.EDISID = SiteList.EDISID AND BDMSiteUsers.UserType = 2
JOIN	Users AS RMUsers ON RMUsers.ID = RMSiteUsers.UserID AND RMUsers.Anonymise = 0 AND RMUsers.Deleted = 0 AND RMUsers.WebActive = 1
JOIN	Users AS BDMUsers ON BDMUsers.ID = BDMSiteUsers.UserID AND BDMUsers.Anonymise = 0 AND BDMUsers.Deleted = 0 AND BDMUsers.WebActive = 1
LEFT OUTER JOIN #UserLogins AS RMLogins ON RMLogins.UserID = RMUsers.ID
LEFT OUTER JOIN #UserLogins AS BDMLogins ON BDMLogins.UserID = BDMUsers.ID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, CAST(SiteProperties.Value AS FLOAT) AS Value
	FROM SiteProperties
	JOIN Properties 
	  ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'RED Value'
	) AS REDValues
  ON REDValues.EDISID = SiteList.EDISID
LEFT JOIN (
	SELECT DISTINCT EDISID
	FROM
	(
	SELECT ISNULL(PrimaryEDIS.PrimaryEDISID, WeeklyDispense.EDISID) AS EDISID,
		   WeeklyDispense.Pump,
		   WeeklyDispense.ProductID,
		   WeeklyDispense.LocationID,
		   AVG(WeeklyDispense.Volume) AS AvgVolume
	FROM PeriodCacheTradingDispenseWeekly AS WeeklyDispense
	JOIN Products ON Products.ID = WeeklyDispense.ProductID
	JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
	LEFT JOIN (
		SELECT MAX(PrimaryEDISID) AS PrimaryEDISID, SiteGroupSites.EDISID
		FROM(
			  SELECT SiteGroupID, SiteGroupSites.EDISID AS PrimaryEDISID
			  FROM SiteGroupSites 
			  WHERE SiteGroupID IN (SELECT ID FROM SiteGroups WHERE TypeID = 1)
			  AND IsPrimary = 1
			  GROUP BY SiteGroupID, SiteGroupSites.EDISID
		) AS PrimarySites
		JOIN SiteGroupSites ON SiteGroupSites.SiteGroupID = PrimarySites.SiteGroupID
		GROUP BY SiteGroupSites.EDISID
	) AS PrimaryEDIS ON PrimaryEDIS.PrimaryEDISID = WeeklyDispense.EDISID
	WHERE WeeklyDispense.WeekCommencing BETWEEN @From AND @To
	  AND Products.IncludeInLowVolume = 1
	  AND Products.IsMetric = 0
	  AND ProductCategories.IncludeInEstateReporting = 1
	GROUP BY ISNULL(PrimaryEDIS.PrimaryEDISID, WeeklyDispense.EDISID),
		   WeeklyDispense.Pump,
		   WeeklyDispense.ProductID,
		   WeeklyDispense.LocationID
	HAVING AVG(WeeklyDispense.Volume) < @LowVolumeThreshold) AS LowVolumePumps
) AS LowVolumeSites ON LowVolumeSites.EDISID = SiteList.EDISID

DROP TABLE #UserLogins
DROP TABLE #SiteList
DROP TABLE #SiteUsers
DROP TABLE #SitesWithSuspectedTampering


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSiteSummary] TO PUBLIC
    AS [dbo];

