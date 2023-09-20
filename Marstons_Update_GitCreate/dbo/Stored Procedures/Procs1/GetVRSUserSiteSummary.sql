CREATE PROCEDURE [dbo].[GetVRSUserSiteSummary]
(
	@VRSUserID INT 
)
AS

SET NOCOUNT ON

DECLARE @BDMSites TABLE(EDISID INT, UserName VARCHAR(50))
DECLARE @SitesWithSuspectedTampering TABLE(EDISID INT, CaseID INT, EventDate DATETIME, StateID INT)
DECLARE @AllSitesVisible BIT
DECLARE @UserID INT

SELECT @AllSitesVisible = AllSitesVisible
FROM UserTypes
WHERE [ID] = 9

SELECT @UserID = [ID]
FROM Users
WHERE VRSUserID = @VRSUserID

INSERT INTO @SitesWithSuspectedTampering
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
WHERE TamperCaseStatuses.StateID IN (2,5)

INSERT INTO @BDMSites
SELECT Sites.EDISID, UserName
FROM Sites
JOIN UserSites ON UserSites.EDISID = Sites.EDISID
JOIN Users ON Users.[ID] = UserSites.UserID
WHERE UserType = 2

SELECT CAMUsers.UserName AS CAMUserName, 
	   Configuration.PropertyValue AS Company, 
	   Sites.SiteID + ': ' + Sites.[Name] AS [Name],
	   Sites.PostCode,
	   CASE [Status] WHEN 1 THEN 'Installed - Active' 
			   WHEN 2 THEN 'Installed - Closed'
			   WHEN 3 THEN 'Installed - Legals'
			   WHEN 4 THEN 'Installed - Not Reported On'
			   WHEN 5 THEN 'Installed - Written Off'
			   WHEN 6 THEN 'Not Installed - Uplifted'
			   WHEN 7 THEN 'Not Installed - Missing/Not Uplifted By Brulines'
			   WHEN 8 THEN 'Not Installed - System To Be Refit'
			   WHEN 9 THEN 'Not Installed - Non Brulines'
			   WHEN 10 THEN 'Installed - FOT'
			   ELSE 'Unknown' END AS SiteStatus,
	   BDMSites.UserName AS BDMUserName,
	   REDValues.Value AS REDValue,
	   CASE WHEN REDValues.Value < -36 THEN 'CDI' ELSE '' END AS CurrentIssueSite,
   	   CASE WHEN SitesWithSuspectedTampering.EDISID IS NULL THEN '' ELSE 'Tamp' END AS SuspectedTampering,
	   CASE SiteRankingCurrent.Audit WHEN 1 THEN 'Red' WHEN 2 THEN 'Amber' WHEN 3 THEN 'Green' ELSE 'Green' END AS SiteRanking,
	   Visits.LastVisitDate,
	   CASE WHEN REDValues.Value < -36 OR SitesWithSuspectedTampering.EDISID IS NOT NULL THEN Configuration.PropertyValue + ' Yes' ELSE Configuration.PropertyValue + ' 0' END AS IssueSite
FROM Users AS CAMUsers
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN UserSites AS CAMUserSites ON CAMUserSites.UserID = CAMUsers.[ID] OR @AllSitesVisible = 1
JOIN Sites ON Sites.EDISID = CAMUserSites.EDISID
LEFT JOIN @BDMSites AS BDMSites ON BDMSites.EDISID = Sites.EDISID
LEFT JOIN @SitesWithSuspectedTampering AS SitesWithSuspectedTampering ON SitesWithSuspectedTampering.EDISID = Sites.EDISID
LEFT JOIN (SELECT EDISID, MAX(VisitDate) AS LastVisitDate FROM VisitRecords GROUP BY EDISID) AS Visits ON Visits.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT SiteProperties.EDISID, CAST(SiteProperties.Value AS FLOAT) AS Value
	FROM SiteProperties
	JOIN Properties 
	  ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'RED Value'
	) AS REDValues
  ON REDValues.EDISID = Sites.EDISID
LEFT JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = Sites.EDISID
WHERE CAMUsers.UserType = 9
AND CAMUsers.VRSUserID = @VRSUserID
AND Sites.EDISID IN
(
   SELECT EDISID FROM UserSites WHERE UserID = @UserID OR @AllSitesVisible = 1
	 
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
GROUP BY CAMUsers.UserName, 
	   Configuration.PropertyValue, 
	   Sites.SiteID + ': ' + Sites.[Name],
	   Sites.PostCode,
	   CASE [Status] WHEN 1 THEN 'Installed - Active' 
			   WHEN 2 THEN 'Installed - Closed'
			   WHEN 3 THEN 'Installed - Legals'
			   WHEN 4 THEN 'Installed - Not Reported On'
			   WHEN 5 THEN 'Installed - Written Off'
			   WHEN 6 THEN 'Not Installed - Uplifted'
			   WHEN 7 THEN 'Not Installed - Missing/Not Uplifted By Brulines'
			   WHEN 8 THEN 'Not Installed - System To Be Refit'
			   WHEN 9 THEN 'Not Installed - Non Brulines'
			   WHEN 10 THEN 'Installed - FOT'
			   ELSE 'Unknown' END,
	   BDMSites.UserName,
	   REDValues.Value,
	   CASE WHEN REDValues.Value < -36 THEN 'CDI' ELSE '' END,
   	   CASE WHEN SitesWithSuspectedTampering.EDISID IS NULL THEN '' ELSE 'Tamp' END,
	   CASE SiteRankingCurrent.Audit WHEN 1 THEN 'Red' WHEN 2 THEN 'Amber' WHEN 3 THEN 'Green' ELSE 'Green' END,
	   Visits.LastVisitDate,
	   CASE WHEN REDValues.Value < -36 OR SitesWithSuspectedTampering.EDISID IS NOT NULL THEN Configuration.PropertyValue + ' Yes' ELSE Configuration.PropertyValue + ' 0' END,
	   Sites.SiteID
ORDER BY CAMUsers.UserName, Configuration.PropertyValue, Sites.SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVRSUserSiteSummary] TO PUBLIC
    AS [dbo];

