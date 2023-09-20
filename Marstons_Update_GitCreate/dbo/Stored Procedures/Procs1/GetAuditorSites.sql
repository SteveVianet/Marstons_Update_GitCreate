CREATE PROCEDURE [dbo].[GetAuditorSites]
(
    @EDISID INT = NULL
)
AS

--DECLARE @EDISID INT
DECLARE @DatabaseID INT
DECLARE @MultipleAuditors BIT
DECLARE @ServerName VARCHAR(50)
DECLARE @DatabaseName VARCHAR(50)
DECLARE @CustomerName VARCHAR(50)

SET NOCOUNT ON

DECLARE @Glass TABLE ([ID] INT NOT NULL, [Desc] VARCHAR(20) NOT NULL)
INSERT INTO @Glass ([ID], [Desc]) VALUES (0, 'No'), (1, 'Yes'), (2, 'Partial'), (3, 'Key products'), (4, 'Unknown')

DECLARE @Ownership TABLE ([ID] INT NOT NULL, [Desc] VARCHAR(10) NOT NULL)
INSERT INTO @Ownership ([ID], [Desc]) VALUES (0, 'Unknown'), (1, 'Rented'), (2, 'Owned')

DECLARE @Status TABLE ([ID] INT NOT NULL, [Desc] VARCHAR(100) NOT NULL)
INSERT INTO @Status ([ID], [Desc]) VALUES (0, 'Unknown'), (1, 'Installed - Active'), (2, 'Installed - Closed'), (3, 'Installed - Legals'), 
										  (4, 'Installed - Not Reported On'), (5, 'Installed - Written Off'), (6, 'Not Installed - Uplifted'),
										  (7, 'Not Installed - Missing/Not Uplifted By Brulines'), (8, 'Not Installed - System To Be Refit'),
										  (9, 'Not Installed - Non Brulines'), (10, 'Installed - FOT'), (11, 'Installed - Telecoms Active')

DECLARE @SiteManagers TABLE (EDISID INT NOT NULL, BDMID INT, RMID INT, AMID INT)

DECLARE @EarliestDispenseWeCareAbout DATE = DATEADD(Month,-1,GETDATE())

SELECT	@DatabaseID = [ID], 
		@MultipleAuditors = MultipleAuditors, 
		@ServerName = [Server], 
		@DatabaseName = [Name],
		@CustomerName = CompanyName
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
JOIN (  SELECT CAST(Configuration.PropertyValue AS INT) AS Value
        FROM dbo.Configuration
        WHERE Configuration.PropertyName = 'Service Owner ID'
    ) AS LoggerID ON EDISDatabases.ID = LoggerID.Value  -- Allows us to differentiate between identically named Databases (primarily a test server concern)
WHERE Name = DB_NAME()
AND EDISDatabases.[Enabled] = 1         -- Database is Enabled for general use
AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)
 
IF @DatabaseID IS NULL
BEGIN
    SELECT	@DatabaseID = [ID], 
		    @MultipleAuditors = MultipleAuditors, 
		    @ServerName = [Server], 
		    @DatabaseName = [Name],
		    @CustomerName = CompanyName
    FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases
    WHERE Name = DB_NAME()
    AND EDISDatabases.[Enabled] = 1         -- Database is Enabled for general use
    AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)
END

DECLARE @DefaultCDA VARCHAR(50)
SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

--SELECT @CustomerName = PropertyValue
--FROM Configuration
--WHERE PropertyName = 'Company Name'

CREATE TABLE #MaxDispense(EDISID INT, TradingDay DATETIME)
INSERT INTO #MaxDispense(EDISID, TradingDay) 
SELECT EDISID, CAST(MAX(DispenseActions.StartTime) AS DATE)
FROM DispenseActions
WHERE CAST(DispenseActions.StartTime AS DATE) >= @EarliestDispenseWeCareAbout
GROUP BY EDISID

--SELECT @EarliestDispenseWeCareAbout

CREATE TABLE #NewInstalls (EDISID INT NOT NULL, CallID INT NOT NULL)
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

INSERT INTO @SiteManagers
(EDISID, BDMID, RMID, AMID)
SELECT  UserSites.EDISID,
 		MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID,
		MAX(CASE WHEN UserType = 7 THEN UserID ELSE 0 END) AS AMID
FROM UserSites
JOIN Users ON Users.ID = UserSites.UserID
WHERE UserType IN (1,2,7)
GROUP BY UserSites.EDISID

SELECT DISTINCT @DatabaseID AS DatabaseID,
	   Sites.EDISID,
	   @CustomerName AS CustomerName,
	   Sites.SiteID,
	   Sites.Name,
	   Sites.Hidden,
	   CASE WHEN @MultipleAuditors = 1 THEN dbo.udfNiceName(SiteUser) ELSE dbo.udfNiceName(@DefaultCDA) END AS Auditor,
	   Sites.SystemTypeID,
	   ISNULL(Sites.LastDownload, 0) AS LastDownload,
	   @ServerName AS [ServerName],
	   @DatabaseName AS [DatabaseName],
	   ISNULL(MaxDispense.TradingDay, 0) AS LastDispenseDate,
	   ISNULL(SiteCals.GlasswareStateID, 0) AS GlassStateID,
	   GlasswareState.[Desc] AS GlassStateDescription,
	   CASE WHEN LastGPRS.LastGPRSDate >= CAST(DATEADD(MONTH, -1, GETDATE()) AS DATE) THEN 1 ELSE 0 END AS GPRS,
	   Owners.Name AS [Owner],
       CASE 	WHEN LEN(Sites.Address3) = 0 AND LEN(Sites.Address4) = 0 THEN Sites.Address2
				WHEN LEN(Sites.Address3) = 0 THEN Sites.Address4
				ELSE Sites.Address3
		END AS Town,
	   --COALESCE(Sites.Address3, Sites.Address2) AS Town,
	   Sites.PostCode AS PostCode,
	   Sites.TenantName AS TenantName,
	   Sites.[Status] AS StatusID,
	   StatusNames.[Desc] AS StatusDescription,
	   ISNULL(BDMs.UserName, '<None>') AS BDM,
	   ISNULL(RMs.UserName, '<None>') AS RM,
	   SystemTypes.[Description] AS SystemTypeDescription,
	   Sites.Quality AS MonitoringType,
	   Sites.ModemTypeID AS ModemTypeID,
	   ModemTypes.[Description] AS ModemTypeDescription,
	   Sites.AreaID AS AreaID,
	   Areas.[Description] AS AreaDescription,
	   Sites.Region AS RegionID,
	   Regions.[Description] AS RegionDescription,
	   ISNULL(CellarDetails.CellarCount, 1) AS CellarCount,
	   ISNULL(AMs.UserName, '<None>') AS AccountManager,
	   ISNULL(Lease.Value, '<Unknown>') AS LeaseType,
	   Sites.OwnershipStatus AS SiteOwnershipID,
	   SiteOwnership.[Desc] AS SiteOwnershipDescription,
	   ISNULL(Sites.InstallationDate, 0) AS InstallDate,
	   ISNULL(Pumps.PumpCount, 0) AS FlowmeterCount,
	   Sites.CommunicationProviderID AS CommsProviderID,
	   CommunicationProviders.ProviderName AS CommsProviderDescription,
	   SiteContracts.ContractID AS ContractID,
	   ISNULL(Contracts.[Description], 'None') AS ContractName,
	   ISNULL(Contracts.ExpiryDate, 0) AS ContractExpirationDate,
	   ISNULL(Calls.CallCount, 0) AS CompletedCallCount,
	   CASE WHEN Disposed.Value IS NULL THEN 0 ELSE 1 END AS Disposed,
	   CASE WHEN ISNULL(NewInstalls.EDISID, 0) > 0 THEN 'Awaiting Install'
			WHEN Sites.Hidden = 1 THEN 'Non-Installed'
			ELSE 'Installed' END AS LoggerStatus,
	   CASE WHEN Sites.Quality = 0 THEN 'DMS' ELSE 'iDraught' END AS MonitoringTypeDescription,
	   REPLACE(Sites.EDISTelNo, ' ', ''),
	   LastGPRS.LastGPRSDate,
	   Sites.SerialNo,
	   Sites.Address1 AS Street,
	   ISNULL(SiteLocale.Value,'en-GB') AS Locale,
       ISNULL(JobWatchReference.Value, '') AS [ContactReference]
FROM Sites 
LEFT JOIN Owners ON Owners.[ID] = Sites.OwnerID
LEFT JOIN Areas ON Areas.[ID] = Sites.AreaID
LEFT JOIN Regions ON Regions.[ID] = Sites.Region
LEFT JOIN @Status AS StatusNames ON StatusNames.ID = Sites.[Status]
LEFT JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
LEFT JOIN (
	SELECT EDISID, MIN(ContractID) AS ContractID 
	FROM SiteContracts 
	GROUP BY EDISID) AS SiteContracts ON SiteContracts.EDISID = Sites.EDISID
LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
LEFT JOIN #MaxDispense AS MaxDispense ON MaxDispense.EDISID = Sites.EDISID
LEFT JOIN CommunicationProviders ON CommunicationProviders.[ID] = Sites.CommunicationProviderID
LEFT JOIN (
	SELECT ProposedFontSetups.EDISID, GlasswareStateID
	FROM ProposedFontSetups
	JOIN (
		SELECT EDISID, MAX(ID) AS ID
		FROM ProposedFontSetups
		GROUP BY EDISID) AS LatestPFS ON LatestPFS.ID = ProposedFontSetups.ID) AS SiteCals ON SiteCals.EDISID = Sites.EDISID
LEFT JOIN @Glass AS GlasswareState ON GlasswareState.ID = ISNULL(SiteCals.GlasswareStateID, 0)
LEFT JOIN @Ownership AS SiteOwnership ON SiteOwnership.ID = Sites.OwnershipStatus
LEFT JOIN @SiteManagers AS SiteManagers ON SiteManagers.EDISID = Sites.EDISID
LEFT JOIN Users AS BDMs ON BDMs.ID = SiteManagers.BDMID
LEFT JOIN Users AS RMs ON RMs.ID = SiteManagers.RMID
LEFT JOIN Users AS AMs ON AMs.ID = SiteManagers.AMID
FULL JOIN #NewInstalls AS NewInstalls ON NewInstalls.EDISID = Sites.EDISID
LEFT JOIN SiteProperties AS Lease ON Lease.EDISID = Sites.EDISID AND Lease.PropertyID = (SELECT [ID] FROM Properties WHERE [Name] = 'Pub Co Lease Type')
LEFT JOIN SiteProperties AS Disposed ON Disposed.EDISID = Sites.EDISID AND Disposed.PropertyID = (SELECT [ID] FROM Properties WHERE [Name] = 'Disposed To Date')
LEFT JOIN SiteProperties AS JobWatchReference ON JobWatchReference.EDISID = Sites.EDISID AND JobWatchReference.PropertyID = (SELECT [ID] FROM Properties WHERE [Name] = 'JobWatch Reference')
LEFT JOIN (
	SELECT
		SiteGroups.ID AS GroupID,
		Primaries.EDISID AS PrimaryEDISID,
		COUNT(SiteGroupSites.EDISID) AS CellarCount
	FROM 
		SiteGroups
	JOIN 
		SiteGroupSites
		ON SiteGroupSites.SiteGroupID = SiteGroups.ID
	LEFT JOIN (
		SELECT
			EDISID,
			MIN(SiteGroupID) AS SiteGroupID
		FROM
			SiteGroupSites WHERE IsPrimary = 1
		GROUP BY EDISID) AS Primaries
		ON Primaries.SiteGroupID = SiteGroups.ID
	WHERE 
		SiteGroups.TypeID = 1
	GROUP BY 
		SiteGroups.ID,
		Primaries.EDISID) AS CellarDetails ON CellarDetails.PrimaryEDISID = Sites.EDISID
LEFT JOIN (
	SELECT PumpSetup.EDISID, COUNT(*) PumpCount
	FROM PumpSetup
	WHERE ValidTo IS NULL
	GROUP BY PumpSetup.EDISID) AS Pumps ON Pumps.EDISID = Sites.EDISID
LEFT JOIN ModemTypes ON ModemTypes.ID = Sites.ModemTypeID
LEFT JOIN (
	SELECT EDISID, COUNT(*) AS CallCount
	FROM Calls
	WHERE ClosedOn IS NOT NULL
	AND AbortReasonID = 0
	AND CallTypeID = 1
	GROUP BY EDISID) AS Calls ON Calls.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, CAST(Value AS DATE) AS LastGPRSDate
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'Last GPRS connection' 
    AND [Value] LIKE '%-%-%'
) AS LastGPRS ON LastGPRS.EDISID = Sites.EDISID
LEFT JOIN (
	SELECT EDISID, Value
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'International'
) AS SiteLocale ON SiteLocale.EDISID = Sites.EDISID
WHERE @EDISID IS NULL OR Sites.EDISID = @EDISID

DROP TABLE #MaxDispense
DROP TABLE #NewInstalls

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorSites] TO PUBLIC
    AS [dbo];

