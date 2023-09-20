CREATE PROCEDURE [dbo].[GetElectricalWorks]

AS

SET NOCOUNT ON

DECLARE @SiteUsers 		TABLE(EDISID INT NOT NULL PRIMARY KEY,
					RM INT NOT NULL,
					BDM INT NOT NULL,
					RMName VARCHAR(255),
					BDMName VARCHAR(255))

-- Work out BDM and RM for each site (0 means no user)
INSERT INTO @SiteUsers
(EDISID, RM, BDM)
SELECT  UserSites.EDISID,
	MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RM,
	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDM
FROM UserSites WITH (NOLOCK)
JOIN Users WITH (NOLOCK) ON Users.ID = UserSites.UserID
JOIN Sites WITH (NOLOCK) ON Sites.EDISID = UserSites.EDISID
WHERE UserType IN (1,2) AND Sites.Hidden = 0
GROUP BY UserSites.EDISID

UPDATE @SiteUsers
SET BDMName = Users.UserName
FROM @SiteUsers AS SiteUsers
JOIN Users WITH (NOLOCK) ON Users.ID = SiteUsers.BDM

UPDATE @SiteUsers
SET RMName = Users.UserName
FROM @SiteUsers AS SiteUsers
JOIN Users WITH (NOLOCK) ON Users.ID = SiteUsers.RM

SELECT Configuration.PropertyValue AS CompanyName,
	Sites.SiteID,
	Sites.Name,
	Sites.PostCode,	
	ElectricalMinorWorks.VisitedOn AS MinorWorks,
	ElectricalPlug.VisitedOn AS Plug,
	SiteUsers.BDMName AS BDMName,
	SiteUsers.RMName AS RMName,
	ElectricalContractor.VisitedOn AS Contractor,
	Sites.InstallationDate,
	SystemTypes.Description AS SystemType,
	PAT.ApplianceID,
	PAT.TestDate,
	PAT.ReTestDue,
	CertifiedByOther.VisitedOn AS CertifiedByOther
FROM Sites WITH (NOLOCK)
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN @SiteUsers AS SiteUsers ON SiteUsers.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 42 AND VisitedOn IS NOT NULL
	GROUP BY EDISID
) AS ElectricalMinorWorks ON ElectricalMinorWorks.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 43 AND VisitedOn IS NOT NULL
	GROUP BY EDISID
) AS ElectricalPlug ON ElectricalPlug.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 44 AND VisitedOn IS NOT NULL
	GROUP BY EDISID
) AS ElectricalContractor ON ElectricalContractor.EDISID = Sites.EDISID
JOIN SystemTypes ON SystemTypes.ID = Sites.SystemTypeID
LEFT JOIN (
	SELECT Calls.EDISID, ApplianceID, TestDate, ReTestDue
	FROM PATTracking
	JOIN Calls ON Calls.[ID] = PATTracking.CallID
	JOIN (SELECT EDISID, MAX(CallID) AS LastCallID
	FROM PATTracking
	JOIN Calls ON Calls.[ID] = PATTracking.CallID
	GROUP BY EDISID) AS LatestPAT ON LatestPAT.EDISID = Calls.EDISID AND LatestPAT.LastCallID = Calls.[ID]
) AS PAT ON PAT.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(VisitedOn) AS VisitedOn
	FROM CallWorkItems WITH (NOLOCK)
	JOIN Calls WITH (NOLOCK) ON Calls.ID = CallWorkItems.CallID
	WHERE WorkItemID = 56 AND VisitedOn IS NOT NULL
	GROUP BY EDISID
) AS CertifiedByOther ON CertifiedByOther.EDISID = Sites.EDISID
--WHERE (ElectricalMinorWorks.VisitedOn IS NOT NULL OR ElectricalPlug.VisitedOn IS NOT NULL OR  ElectricalContractor.VisitedOn IS NOT NULL)
WHERE (Sites.Hidden = 0)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetElectricalWorks] TO PUBLIC
    AS [dbo];

