CREATE PROCEDURE [dbo].[xx_GetClientEstateReportOLD] AS

SET NOCOUNT ON

CREATE TABLE #SiteGroupSiteCount (GroupID INTEGER NOT NULL, GroupSiteCount INTEGER NOT NULL)
CREATE TABLE #Pumps (EDISID INTEGER NOT NULL, PumpCount INTEGER NOT NULL)
CREATE TABLE #SiteGroupPumpCount (GroupID INTEGER NOT NULL, PumpCount INTEGER NOT NULL)
CREATE TABLE #NewInstalls (EDISID INT NOT NULL, CallID INT NOT NULL)
CREATE TABLE #CompletedCalls (EDISID INT NOT NULL, CallCount INT NOT NULL)
CREATE TABLE #SiteManagers(EDISID INT NOT NULL, BDMID INT, RMID INT, AMID INT)

INSERT INTO #SiteGroupPumpCount
SELECT SiteGroups.[ID], COUNT(*)
FROM PumpSetup
JOIN SiteGroupSites ON SiteGroupSites.EDISID = PumpSetup.EDISID
JOIN SiteGroups ON SiteGroups.[ID] = SiteGroupSites.SiteGroupID
WHERE ValidTo IS NULL
AND SiteGroups.TypeID = 1
GROUP BY SiteGroups.[ID]

--SELECT * FROM #SiteGroupPumpCount

INSERT INTO #SiteGroupSiteCount
SELECT SiteGroups.[ID], COUNT(SiteGroupSites.EDISID) AS GroupSiteCount
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE SiteGroups.TypeID = 1
GROUP BY SiteGroups.[ID]

--SELECT * FROM #SiteGroupSiteCount

INSERT INTO #Pumps
SELECT PumpSetup.EDISID, COUNT(*)
FROM PumpSetup
WHERE ValidTo IS NULL
GROUP BY PumpSetup.EDISID

--SELECT * FROM #Pumps

INSERT INTO #NewInstalls
SELECT	Calls.EDISID,
		MAX(Calls.[ID])
FROM CallStatusHistory
JOIN
(
SELECT CallID, MAX(ChangedOn) AS LatestChangeDate
FROM CallStatusHistory
GROUP BY CallID
) AS LatestCallChanges ON LatestCallChanges.CallID = CallStatusHistory.CallID
AND LatestCallChanges.LatestChangeDate = CallStatusHistory.ChangedOn
JOIN Calls ON Calls.[ID] = CallStatusHistory.CallID
WHERE Calls.AbortReasonID = 0
AND Calls.CallTypeID = 2
AND StatusID NOT IN (4, 5)
GROUP BY Calls.EDISID

--SELECT * FROM #NewInstalls

INSERT INTO #CompletedCalls
SELECT EDISID, COUNT(*)
FROM Calls
WHERE ClosedOn IS NOT NULL
AND AbortReasonID = 0
AND CallTypeID = 1
GROUP BY EDISID

--SELECT * FROM #CompletedCalls

INSERT INTO #SiteManagers
(EDISID, BDMID, RMID, AMID)
SELECT  UserSites.EDISID,
 		MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID,
		MAX(CASE WHEN UserType = 7 THEN UserID ELSE 0 END) AS AMID
FROM UserSites
JOIN Users ON Users.ID = UserSites.UserID
WHERE UserType IN (1,2,7)
GROUP BY UserSites.EDISID

--SELECT * FROM #SiteManagers

SELECT Owners.[Name] AS Owner,
       Sites.EDISID,
       Sites.SiteID,
       Sites.[Name] AS SiteName,
       Sites.Address3 AS Town,
       Sites.PostCode,
       Sites.TenantName,
       (CASE 	WHEN ISNULL(NewInstalls.EDISID, 0) > 0 THEN 'Awaiting Install'
		WHEN Sites.Hidden = 1 THEN 'Non-Installed'
		ELSE 'Installed'
	END) AS LoggerStatus,
       ISNULL(BDMs.UserName, '<None>') AS BusinessManager,
       ISNULL(RMs.UserName, '<None>') AS RegionalManager,
       ISNULL(AMs.UserName, '<None>') AS AccountManager,
       SystemTypes.[Description] AS SystemType,
       Sites.Region,
       Areas.[Description] AS Area,
       (CASE WHEN SiteProperties.Value IS NULL THEN 0 ELSE 1 END) AS Disposed,
       (CASE WHEN Sites.OwnershipStatus = 0 THEN 'Unknown' WHEN Sites.OwnershipStatus = 1 THEN 'Rented' ELSE 'Owned' END) AS SiteOwnership,
       CommunicationProviders.ProviderName AS Provider,
       ISNULL(Sites.InstallationDate, 0) AS InstallationDate,
       ISNULL(Contracts.[Description], 'None') AS Contract,
       ISNULL(Contracts.ExpiryDate, 0) AS ExpiryDate,
       ISNULL(Pumps.PumpCount, 0) AS NoOfFlowmeters,
       1 AS Cellars,
       ISNULL(CompletedCalls.CallCount, 0) AS CallCount,
       ISNULL(SiteCals.GlasswareStateID, 0) AS CalibrationStatus,
       Sites.Status AS SiteStatus
FROM Sites
LEFT JOIN #SiteManagers AS SiteManagers ON SiteManagers.EDISID = Sites.EDISID
LEFT JOIN Users AS BDMs ON BDMs.ID = SiteManagers.BDMID
LEFT JOIN Users AS RMs ON RMs.ID = SiteManagers.RMID
LEFT JOIN Users AS AMs ON AMs.ID = SiteManagers.AMID
FULL JOIN #NewInstalls AS NewInstalls ON NewInstalls.EDISID = Sites.EDISID
LEFT JOIN Owners ON Owners.[ID] = Sites.OwnerID
LEFT JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
LEFT JOIN Areas ON Areas.[ID] = Sites.AreaID
LEFT JOIN CommunicationProviders ON CommunicationProviders.[ID] = Sites.CommunicationProviderID
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
LEFT JOIN #Pumps AS Pumps ON Pumps.EDISID = Sites.EDISID
LEFT JOIN SiteProperties ON SiteProperties.EDISID = Sites.EDISID AND SiteProperties.PropertyID = (SELECT [ID] FROM Properties WHERE [Name] = 'Disposed To Date')
LEFT JOIN #CompletedCalls AS CompletedCalls ON CompletedCalls.EDISID = Sites.EDISID
--FULL JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
LEFT JOIN (
	-- Get all sites and an overall calibration result (full-glass, key-glass, partial-glass or non-glass)
	SELECT  COALESCE(SitePumpCals.EDISID, Sites.EDISID) AS EDISID,
		CASE
		  WHEN SUM(Glass) = 0 THEN 0
		  WHEN SUM(Glass) = COUNT(Pump) THEN 1
		  WHEN SUM(KeyGlass) >= SUM(KeyProduct) THEN 3
		  ELSE 2
		  END AS GlasswareStateID
	FROM Sites
	FULL JOIN (
		-- Get all known flowmeters, if they are calibrated on glassware, a key producd, and a key product calibrated on glassware
		SELECT  PumpSetup.EDISID,
			PumpSetup.Pump,
			CASE WHEN GlassCalFonts.Pump IS NULL THEN 0 ELSE 1 END AS Glass,
			CASE WHEN SiteKeyProducts.ProductID IS NULL THEN 0 ELSE 1 END AS KeyProduct,
			CASE WHEN (GlassCalFonts.Pump IS NOT NULL) AND (SiteKeyProducts.ProductID IS NOT NULL) THEN 1 ELSE 0 END AS KeyGlass
		FROM PumpSetup
		JOIN Sites ON Sites.EDISID = PumpSetup.EDISID
		JOIN Products ON Products.ID = PumpSetup.ProductID
		FULL JOIN SiteKeyProducts ON SiteKeyProducts.ProductID = Products.ID AND SiteKeyProducts.EDISID = PumpSetup.EDISID
		FULL JOIN (
			-- Get all glassware-calibrated sites and flowmeters
			SELECT EDISID, PFS.FontNumber AS Pump
			FROM ProposedFontSetupItems AS PFS
			JOIN (	SELECT EDISID, FontNumber, MAX(ProposedFontSetupID) AS SetupID
				FROM ProposedFontSetupItems
				JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
				WHERE JobType IN (1,2) AND GlasswareID IS NOT NULL
				GROUP BY EDISID, FontNumber
			) AS GlassCals ON GlassCals.SetupID = PFS.ProposedFontSetupID AND GlassCals.FontNumber = PFS.FontNumber
		) AS GlassCalFonts ON GlassCalFonts.EDISID = PumpSetup.EDISID AND GlassCalFonts.Pump = PumpSetup.Pump
		WHERE PumpSetup.ValidTo IS NULL
		AND PumpSetup.InUse = 1
		AND Products.IsWater = 0
		AND Products.IsMetric = 0
		AND Sites.Hidden = 0
	) AS SitePumpCals ON SitePumpCals.EDISID = Sites.EDISID
	WHERE Sites.Hidden = 0
	GROUP BY COALESCE(SitePumpCals.EDISID, Sites.EDISID)
) AS SiteCals ON SiteCals.EDISID = Sites.EDISID
GROUP BY Owners.[Name],
       Sites.EDISID,
       Sites.SiteID,
       Sites.[Name],
       Sites.Address3,
       Sites.PostCode,
       Sites.TenantName,
       (CASE 	WHEN ISNULL(NewInstalls.EDISID, 0) > 0 THEN 'Awaiting Install'
		WHEN Sites.Hidden = 1 THEN 'Non-Installed'
		ELSE 'Installed'
	END),
       ISNULL(BDMs.UserName, '<None>'),
       ISNULL(RMs.UserName, '<None>'),
       ISNULL(AMs.UserName, '<None>'),
       SystemTypes.[Description],
       Sites.Region,
       Areas.[Description],
       (CASE WHEN SiteProperties.Value IS NULL THEN 0 ELSE 1 END),
       (CASE WHEN Sites.OwnershipStatus = 0 THEN 'Unknown' WHEN Sites.OwnershipStatus = 1 THEN 'Rented' ELSE 'Owned' END),
       CommunicationProviders.ProviderName,
       Sites.InstallationDate,
       Contracts.[Description],
       Contracts.ExpiryDate,
       Pumps.PumpCount,
       ISNULL(CompletedCalls.CallCount, 0),
      SiteCals.GlasswareStateID,
Sites.Status
ORDER BY Sites.SiteID DESC

DROP TABLE #SiteGroupSiteCount
DROP TABLE #Pumps
DROP TABLE #SiteGroupPumpCount
DROP TABLE #NewInstalls
DROP TABLE #CompletedCalls
DROP TABLE #SiteManagers

