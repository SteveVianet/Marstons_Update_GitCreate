CREATE PROCEDURE [dbo].[GetWebUserSiteList]
(
    @UserID           INT,
    @EDISID			  INT = NULL,
	@IsLocalUser	  BIT = 0
)
AS

/*
	Standard = 2:25
	No-Lock = 2:15
	Limited (Current Year, based on TradingDate) = 0:24 / 0:48 / 0:40 (88% impact missing index on external sales query)
	Limited (Current Year, based on SaleDate) = 3:00 (gave up, would've taken longer)
	Limited (6 Months, based on TradingDate) = 0:39 / 0:24 / 0:19 (88% impact missing index on external sales query)
	Limited (3 Months, based on TradingDate) = 0:17 / 0:16 / 0:18 (86% impact missing index on external sales query)
	
	Suggested for queries using TradingDate as a restriction:
	CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
		ON [dbo].[Sales] ([External],[EDISID],[TradingDate])
*/

-- @UserID=24378,@EDISID=NULL,@IsLocalUser=0

--DECLARE    @UserID           INT = 24378
--DECLARE    @EDISID			  INT = NULL
--DECLARE	@IsLocalUser	  BIT = 0

SET DATEFIRST 1
SET NOCOUNT ON

DECLARE @AuditDate		DATETIME
DECLARE @Anonymise		BIT
DECLARE @UserHasAllSites	BIT
DECLARE @DatabaseID		INTEGER
DECLARE @UserTypeID		INTEGER
DECLARE @Today			DATETIME
DECLARE @Yesterday		DATETIME
DECLARE @FourWeeksAgo		DATETIME
DECLARE @DefaultCDA		VARCHAR(50)

CREATE TABLE #WebSiteSessions (	SessionID 		INT NOT NULL, 
				ClientIPAddress 	VARCHAR(15) NOT NULL,
				UserAgent 		VARCHAR(255) NOT NULL, 
				Authenticated 		BIT NOT NULL,
				[Password] 		VARCHAR(255) NOT NULL,
				[Login] 		VARCHAR(255) NOT NULL,
				UserName 		VARCHAR(255),
				EMail 			VARCHAR(255),
				UserType 		VARCHAR(255),
				LoggedOn 		DATETIME,
				LoggedOff 		DATETIME,
				MinutesOnline 		FLOAT,
				Anonymise		BIT
				)

CREATE TABLE #SC (	EDISID 			INT NOT NULL,
			[Type] 			INT NOT NULL,
			HeadingType 		INT,
			HeadingTypeDescription 	VARCHAR(100),
			[ID] 			INT NOT NULL,
			Latest 			DATETIME,
			[Text] 			VARCHAR(924)
		)

CREATE CLUSTERED INDEX IX_EDISID_Types ON #SC(EDISID, [Type], HeadingType)

CREATE TABLE #SitesList
(				Counter						INT IDENTITY(1,1) PRIMARY KEY,
				EDISID              		INT NOT NULL UNIQUE,
				CompanyName					VARCHAR(255) DEFAULT '',
				SubCompanyName				VARCHAR(255),
				AuditedUpTo					DATETIME,
				SiteID              		VARCHAR(15),
				[Name]              		VARCHAR(60),
				Street              		VARCHAR(50),
				Town						VARCHAR(50),
				PostCode					VARCHAR(8),
				LastDownload				DATETIME,
				RMName              		VARCHAR(255) DEFAULT '',
				BDMName             		VARCHAR(255) DEFAULT '',
				RMID						INT DEFAULT 0,
				BDMID						INT DEFAULT 0,
				LatestSalesDate				DATETIME,
				HasAnySales					BIT DEFAULT 0,
				SiteOnline					DATETIME,
				HasInternalSales    		BIT DEFAULT 0,
				Locale              		VARCHAR(10),
				SiteArea					VARCHAR(50),
				LicenseeLogins				INT DEFAULT 0,
				LicenseeLatestLoginTime 	DATETIME,
				StatusPouringYield  		INT DEFAULT 6,
				CommentPouringYield 		VARCHAR(1024) DEFAULT '',
				StatusTillYield     		INT DEFAULT 6,
				CommentTillYield    		VARCHAR(1024) DEFAULT '',
				StatusCleaning      		INT DEFAULT 6,
				CommentCleaning     		VARCHAR(1024) DEFAULT '',
				StatusAlarm         		BIT DEFAULT 0,
				StatusDeliveries    		INT DEFAULT 6,
				CommentDeliveries   		VARCHAR(1024) DEFAULT '',
				RankingCellarTemperature	INT DEFAULT 6,
				RankingRemoteCooling		INT DEFAULT 6,
				RankingLineCleaning			INT DEFAULT 6,
				RankingThroughput			INT DEFAULT 6,
				RankingTemperature			INT DEFAULT 6,
				RankingPouringYield			INT DEFAULT 6,
				RankingTillYield			INT DEFAULT 6,
				RankingVariance				INT DEFAULT 6,
				DateTimePouringYield 		DATETIME,
				DateTimeTillYield   		DATETIME,
				DateTimeCleaning    		DATETIME,
				DateTimeDeliveries  		DATETIME,
				SmallVolumeUnit        		VARCHAR(50),
				LargeVolumeUnit        		VARCHAR(50),
				ContainerVolumeUnit        	VARCHAR(50),
				TemperatureUnit     		VARCHAR(50),
				SiteLive            		BIT,
				IsIDraught					BIT,
				HasEquipment				BIT DEFAULT 0,
				DrinkActionID				INT,
				IsVRSMember					BIT,
				Auditor						VARCHAR(50),
				HasLatestData				BIT,
				SiteGroupID					INT,
				Club						INT,
				RetailCashValue				FLOAT,
				OperationalCashValue		FLOAT,
				LowVolumeThreshold			INT,
				RSICustomer					VARCHAR(1),
				SiteRankingEquipmentAmbient	INT DEFAULT 6,
				SiteRankingEquipmentRecirc	INT DEFAULT 6,
				SiteRankingCleaning			INT DEFAULT 6,
				SiteRankingCleaningKeg		INT DEFAULT 6,
				SiteRankingCleaningCask		INT DEFAULT 6,
				SiteRankingThroughput		INT DEFAULT 6,
				SiteRankingThroughputKeg	INT DEFAULT 6,
				SiteRankingThroughputCask	INT DEFAULT 6,
				SiteRankingTemperature		INT DEFAULT 6,
				SiteRankingTemperatureKeg	INT DEFAULT 6,
				SiteRankingTemperatureCask	INT DEFAULT 6,
				SiteRankingPouringYield		INT DEFAULT 6,
				SiteRankingPouringYieldKeg	INT DEFAULT 6,
				SiteRankingPouringYieldCask	INT DEFAULT 6,
				SiteRankingTillYield		INT DEFAULT 6,
				SiteRankingTillYieldKeg		INT DEFAULT 6,
				SiteRankingTillYieldCask	INT DEFAULT 6,
				County						VARCHAR(50),
				SystemTypeID				INT,
				IncludeCleaningWasteInOverallYield	BIT
				)
CREATE INDEX IDX_EDISID ON #SitesList (EDISID)


SELECT @Today = CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
SELECT @Yesterday = DATEADD(DAY, -1, @Today)
SELECT @FourWeeksAgo = DATEADD(wk, -4, @Today)

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @DefaultCDA = PropertyValue
FROM Configuration
WHERE PropertyName = 'AuditorName'

INSERT INTO #WebSiteSessions 
(SessionID, ClientIPAddress, UserAgent, Authenticated, [Login], [Password], UserName, EMail, UserType, LoggedOn, LoggedOff, MinutesOnline, Anonymise)
EXEC [SQL1\SQL1].ServiceLogger.dbo.[GetWebSiteSessionsOverview] @DatabaseID, @EDISID, 0, 1, @FourWeeksAgo, @Today

-- Which sites are we allowed to see?
SELECT @UserHasAllSites = AllSitesVisible, @Anonymise = dbo.Users.Anonymise, @UserTypeID = UserTypes.ID
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

-- Get relevant EDISIDs for this user
INSERT INTO #SitesList (EDISID)
SELECT Sites.EDISID
FROM Sites
WHERE
(
	EDISID = @EDISID AND @IsLocalUser = 1
)
OR
(
	(
	   (Sites.EDISID = @EDISID) AND (
					 (@UserHasAllSites = 1) OR 
					 (Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID)))
	 
	)
	OR
	(
	  (@EDISID IS NULL) AND (
			(@UserHasAllSites = 1) OR 
			(Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID))
		)

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
)
AND Sites.Hidden = 0

-- Get BDM and RM info for each site
UPDATE #SitesList
SET 	BDMID = SiteManagers.BDMID,
	RMID = SiteManagers.RMID,
	BDMName = BDMUser.UserName,
	RMName = RMUser.UserName
FROM (
	SELECT UserSites.EDISID,
	 	MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
		MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
	FROM UserSites
	JOIN Users ON Users.ID = UserSites.UserID
	JOIN #SitesList AS SitesList ON UserSites.EDISID = SitesList.EDISID
	WHERE UserType IN (1,2) AND UserSites.EDISID = SitesList.EDISID
	GROUP BY UserSites.EDISID
) AS SiteManagers
JOIN #SitesList AS SitesList ON SitesList.EDISID = SiteManagers.EDISID
JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID
JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID

-- Get audit date for DMS and product variance
SELECT @AuditDate = DATEADD(day, -DATEPART(dw, CAST(Configuration.PropertyValue AS DATETIME)) +7, CAST(Configuration.PropertyValue AS DATETIME))
FROM Configuration
WHERE PropertyName = 'AuditDate'

-- Get basic site details
UPDATE #SitesList
SET	SubCompanyName = Owners.Name,
	AuditedUpTo = @AuditDate,
	SiteID = Sites.SiteID,
	[Name] = Sites.Name,
	Street = Sites.Address1,
	Town =	CASE 	WHEN LEN(Sites.Address3) = 0 AND LEN(Sites.Address4) = 0 THEN Sites.Address2
			WHEN LEN(Sites.Address3) = 0 THEN Sites.Address4
			ELSE Sites.Address3
		END,
	PostCode = Sites.PostCode,
	LastDownload =	CASE	WHEN Sites.Quality = 1 THEN ISNULL(Sites.LastDownload, Sites.SiteOnline)
				WHEN Sites.Quality = 0 AND UPPER(ShowLatestDataOnWeb.Value) = 'TRUE' THEN ISNULL(Sites.LastDownload, Sites.SiteOnline)
				WHEN @AuditDate > ISNULL(Sites.LastDownload, Sites.SiteOnline) THEN ISNULL(Sites.LastDownload, Sites.SiteOnline)
				ELSE @AuditDate
			END,
	HasLatestData = CASE	WHEN Sites.Quality = 1 THEN 1
				WHEN Sites.Quality = 0 AND UPPER(ShowLatestDataOnWeb.Value) = 'TRUE' THEN 1
				ELSE 0
			END,
	SiteArea = ISNULL(Areas.[Description],''),
	SiteOnline = Sites.SiteOnline,
	Locale =	CASE	WHEN SiteLocations.International IS NULL THEN 'en'
				WHEN REPLACE(SiteLocations.International, ' ', '') = '' THEN 'en'
				ELSE REPLACE(SiteLocations.International, ' ', '')
			END,
	SmallVolumeUnit = ISNULL(SmallUnit.UnitType, 'Default'),
	LargeVolumeUnit = ISNULL(LargeUnit.UnitType, 'Default'),
	ContainerVolumeUnit = ISNULL(ContainerUnit.UnitType, 'Default'),
	TemperatureUnit = ISNULL(TemperatureUnit.UnitType, 'Default'),
	IsIDraught = Sites.Quality,
	SiteLive = ~Sites.Hidden,
	DrinkActionID = ISNULL(CAST(DrinkActions.Value AS INT), 1),
	IsVRSMember = Sites.IsVRSMember,
	LatestSalesDate = Sites.SiteOnline,
	LicenseeLatestLoginTime = Sites.SiteOnline,
	DateTimePouringYield = Sites.SiteOnline,
	DateTimeTillYield = Sites.SiteOnline,
	DateTimeCleaning = Sites.SiteOnline,
	DateTimeDeliveries = Sites.SiteOnline,
	Auditor =	CASE	WHEN LEN(SiteUser) > 0 THEN SiteUser 
				ELSE @DefaultCDA
			END,
	Club = Sites.ClubMembership,
	RSICustomer = RSI.Value,
	County = CASE WHEN LEN(Sites.Address4) <> 0 AND LEN(Sites.Address3) <> 0 THEN Sites.Address4 ELSE '' END,
	SystemTypeID = Sites.SystemTypeID,
	RetailCashValue = Owners.POSYieldCashValue,
	OperationalCashValue = Owners.PouringYieldCashValue,
	LowVolumeThreshold = Owners.ThroughputLowValue,
	IncludeCleaningWasteInOverallYield = Owners.IncludeCleaningWasteInOverallYield
FROM Sites
JOIN #SitesList AS SitesList ON SitesList.EDISID = Sites.EDISID
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
LEFT OUTER JOIN Areas ON Areas.ID = Sites.AreaID AND @UserTypeID IN (1,2)
LEFT OUTER JOIN (
	SELECT EDISID, SiteProperties.Value
	FROM SiteProperties 
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Name = 'RSICustomer'
) AS RSI ON RSI.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT EDISID, SiteProperties.Value
	FROM SiteProperties 
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Name = 'Drink Actions Parameter'
) AS DrinkActions ON DrinkActions.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT EDISID, SiteProperties.Value
	FROM SiteProperties
	JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
	WHERE Properties.[Name] = 'ShowLatestDataOnWeb'
) AS ShowLatestDataOnWeb ON ShowLatestDataOnWeb.EDISID = Sites.EDISID 
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS International
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'International'
) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS UnitType
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'Small Unit'
) AS SmallUnit ON SmallUnit.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS UnitType
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'Large Unit'
) AS LargeUnit ON LargeUnit.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS UnitType
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'Container Unit'
) AS ContainerUnit ON ContainerUnit.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS UnitType
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'Temperature Unit'
) AS TemperatureUnit ON TemperatureUnit.EDISID = Sites.EDISID

-- Get site grouping information
UPDATE #SitesList
SET SiteGroupID = GroupID
FROM (
	SELECT Sites.EDISID, SiteGroups.ID AS GroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	JOIN #SitesList AS Sites ON Sites.EDISID = SiteGroupSites.EDISID) AS Groups
JOIN #SitesList AS SitesList ON SitesList.EDISID = Groups.EDISID

-- Mark sites which have equipment (default is 0)
UPDATE #SitesList
SET HasEquipment = 1
FROM EquipmentItems
JOIN #SitesList AS SitesList ON SitesList.EDISID = EquipmentItems.EDISID

-- Mark grouped sites which have equipment (default is 0)
UPDATE #SitesList
SET HasEquipment = 1
FROM EquipmentItems
JOIN SiteGroupSites ON SiteGroupSites.EDISID = EquipmentItems.EDISID
JOIN #SitesList AS Sites ON Sites.SiteGroupID = SiteGroupSites.SiteGroupID

-- Mark sites which have unresolved alerts/alarms (default is 0)
UPDATE #SitesList
SET StatusAlarm = 1
FROM EquipmentItems
JOIN #SitesList AS SitesList ON SitesList.EDISID = EquipmentItems.EDISID
WHERE EquipmentItems.LastAlarmingReading >= DATEADD(day, -7, GETDATE())

-- Get sales info
UPDATE #SitesList
SET LatestSalesDate = LatestSales.LatestSaleDate, HasAnySales = 1
FROM ( 
	SELECT Sales.EDISID, MAX(Sales.TradingDate) AS LatestSaleDate
	FROM Sales WITH (NOLOCK)
	JOIN #SitesList AS SitesList ON SitesList.EDISID = Sales.EDISID
	WHERE [TradingDate] >= DATEADD(MONTH, -3, GETDATE())
	GROUP BY Sales.EDISID
) AS LatestSales
JOIN #SitesList AS SitesList ON SitesList.EDISID = LatestSales.EDISID

UPDATE #SitesList
SET LatestSalesDate = LatestSales.LatestSaleDate, HasInternalSales = 1
FROM ( 
	SELECT Sales.EDISID, MAX(Sales.TradingDate) AS LatestSaleDate
	FROM Sales WITH (NOLOCK)
	JOIN #SitesList AS SitesList ON SitesList.EDISID = Sales.EDISID
	WHERE [External] = 0
	AND [TradingDate] >= DATEADD(MONTH, -3, GETDATE())
	GROUP BY Sales.EDISID
) AS LatestSales
JOIN #SitesList AS SitesList ON SitesList.EDISID = LatestSales.EDISID

---- Number of licensee logins
UPDATE #SitesList
SET	LicenseeLogins = LoginSummary.UserCount,
	LicenseeLatestLoginTime = LoginSummary.LatestLogin
FROM (
	SELECT EDISID, COUNT(LoggedOn) AS UserCount, MAX(LoggedOn) AS LatestLogin
	FROM #WebSiteSessions AS WebSessions
	JOIN Users ON Users.[Login] = WebSessions.[Login] AND Users.[Password] = WebSessions.[Password] AND Users.UserType IN (5,6)
	JOIN UserSites ON UserSites.UserID = Users.ID
	GROUP BY EDISID
) AS LoginSummary
JOIN #SitesList AS SitesList ON SitesList.EDISID = LoginSummary.EDISID

--We should be able to replace LoginSummary with this, but it will often run slow.  Don't know why.
/*
SELECT WebSiteSessionSites.EDISID AS EDISID, COUNT(*) AS UserCount, MAX(WebSiteSession.DateTime) AS LatestLogin
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSession AS WebSiteSession
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionDatabases AS WebSiteSessionDatabases ON WebSiteSessionDatabases.SessionID = WebSiteSession.ID
JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.WebSiteSessionSites AS WebSiteSessionSites ON WebSiteSessionSites.SessionID = WebSiteSession.ID
JOIN #SitesList AS SitesList ON SitesList.EDISID = WebSiteSessionSites.EDISID
WHERE Testing = 0
AND WebSiteSessionDatabases.UserTypeID IN (5, 6)
AND WebSiteSession.[DateTime] BETWEEN @FourWeeksAgo AND @Today
AND [WebSiteSession].[Testing] = 0
AND [WebSiteSession].[WebSiteID] = 1
AND [WebSiteSession].[Authenticated] = 1
AND WebSiteSessionDatabases.Anonymise = 0
AND WebSiteSessionDatabases.DatabaseID = @DatabaseID
GROUP BY WebSiteSessionSites.EDISID
*/

 --Get latest site comments into per-site speed table
IF ( (@Anonymise = 0) OR (@UserTypeID NOT IN (5, 6)) )
BEGIN
	-- Get the latest i-draught comments
	INSERT INTO #SC
	(EDISID, [Type], HeadingType, [ID])
	SELECT SiteComments.EDISID, [Type], HeadingType, MAX([ID])
	FROM SiteComments
	JOIN #SitesList AS SitesList ON SitesList.EDISID = SiteComments.EDISID
	WHERE [Type] IN (6)
	AND [Date] >= SitesList.SiteOnline
	AND [Date] >= DATEADD(day, -10, GETDATE())
	GROUP BY SiteComments.EDISID, [Type], HeadingType

	-- Get the latest Auditor (DMS) comments
	INSERT INTO #SC
	(EDISID, [Type], [ID])
	SELECT SiteComments.EDISID, [Type], MAX([ID])
	FROM SiteComments
	JOIN #SitesList AS SitesList ON SitesList.EDISID = SiteComments.EDISID
	WHERE [Type] IN (1)
	AND [Date] >= SitesList.SiteOnline
	GROUP BY SiteComments.EDISID, [Type]

	-- Add the Heading Types to the Auditor (DMS) comments
	-- This isn't actually used (might be speed-up to remove?)
	UPDATE #SC
	SET HeadingType = SiteComments.HeadingType
	FROM SiteComments
	JOIN #SC ON #SC.ID = SiteComments.ID
	WHERE SiteComments.[Type] = 1
	
	-- Add the comment text
	UPDATE #SC
	SET [Text] = LEFT(SiteComments.[Text],900), Latest = SiteComments.[Date]
	FROM SiteComments
	JOIN #SC ON #SC.ID = SiteComments.ID
	
	---- Add the secondary Heading Types to all comments
	---- This is only used for Auditor (DMS) comments, could speed up?
	UPDATE #SC
	SET HeadingTypeDescription = SiteCommentHeadingTypes.[Description]
	FROM SiteCommentHeadingTypes
	JOIN #SC ON #SC.HeadingType = SiteCommentHeadingTypes.ID

END

-- Site traffic lights (rankings)
UPDATE #SitesList
SET 	StatusCleaning = SiteRankingCurrent.Cleaning,
	StatusTillYield = SiteRankingCurrent.TillYield,
	StatusDeliveries = SiteRankingCurrent.Audit,
	StatusPouringYield = SiteRankingCurrent.PouringYield,
	RankingCellarTemperature = ISNULL(SiteRankingCurrent.EquipmentAmbientTL, 6),
	RankingRemoteCooling = ISNULL(SiteRankingCurrent.EquipmentRecircTL, 6),
	RankingLineCleaning = ISNULL(SiteRankingCurrent.CleaningTL, 6),
	RankingThroughput = ISNULL(SiteRankingCurrent.ThroughputTL, 6),
	RankingTemperature = ISNULL(SiteRankingCurrent.TemperatureTL, 6),
	RankingPouringYield = ISNULL(SiteRankingCurrent.PouringYieldTL, 6),
	RankingTillYield = ISNULL(SiteRankingCurrent.TillYieldTL, 6),
	RankingVariance = ISNULL(SiteRankingCurrent.Audit, 6),
	SiteRankingEquipmentAmbient = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteEquipmentAmbientTL ELSE 6 END, 6),
	SiteRankingEquipmentRecirc = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteEquipmentRecircTL ELSE 6 END, 6),
	SiteRankingCleaning = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteCleaningTL ELSE 6 END, 6),
	SiteRankingCleaningKeg = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteCleaningKegTL ELSE 6 END, 6),
	SiteRankingCleaningCask = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteCleaningCaskTL ELSE 6 END, 6),
	SiteRankingThroughput = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteThroughputTL ELSE 6 END, 6),
	SiteRankingThroughputKeg = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteThroughputKegTL ELSE 6 END, 6),
	SiteRankingThroughputCask = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteThroughputCaskTL ELSE 6 END, 6),
	SiteRankingTemperature = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTemperatureTL ELSE 6 END, 6),
	SiteRankingTemperatureKeg = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTemperatureKegTL ELSE 6 END, 6),
	SiteRankingTemperatureCask = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTemperatureCaskTL ELSE 6 END, 6),
	SiteRankingPouringYield = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SitePouringYieldTL ELSE 6 END, 6),
	SiteRankingPouringYieldKeg = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SitePouringYieldKegTL ELSE 6 END, 6),
	SiteRankingPouringYieldCask = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SitePouringYieldCaskTL ELSE 6 END, 6),
	SiteRankingTillYield = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTillYieldTL ELSE 6 END, 6),
	SiteRankingTillYieldKeg = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTillYieldKegTL ELSE 6 END, 6),
	SiteRankingTillYieldCask = ISNULL(CASE WHEN LastUpdated >= @Yesterday THEN SiteRankingCurrent.SiteTillYieldCaskTL ELSE 6 END, 6)
FROM SiteRankingCurrent
JOIN #SitesList AS SitesList ON SitesList.EDISID = SiteRankingCurrent.EDISID

-- Site comments
UPDATE #SitesList
SET	CommentPouringYield = Comments.Text,
	DateTimePouringYield = Comments.Latest
FROM #SC AS Comments
JOIN #SitesList AS SitesList ON SitesList.EDISID = Comments.EDISID
WHERE Comments.Type = 6 AND HeadingType = 1010

UPDATE #SitesList
SET	CommentTillYield = Comments.Text,
	DateTimeTillYield = Comments.Latest
FROM #SC AS Comments
JOIN #SitesList AS SitesList ON SitesList.EDISID = Comments.EDISID
WHERE Comments.Type = 6 AND HeadingType = 1011

UPDATE #SitesList
SET	CommentCleaning = Comments.Text,
	DateTimeCleaning = Comments.Latest
FROM #SC AS Comments
JOIN #SitesList AS SitesList ON SitesList.EDISID = Comments.EDISID
WHERE Comments.Type = 6 AND HeadingType = 1002

UPDATE #SitesList
SET	CommentDeliveries = (HeadingTypeDescription + ' ' + [Text]),
	DateTimeDeliveries = Comments.Latest
FROM #SC AS Comments
JOIN #SitesList AS SitesList ON SitesList.EDISID = Comments.EDISID
WHERE Comments.Type = 1 AND @UserTypeID NOT IN (5,6) 

UPDATE #SitesList
SET CompanyName = DBs.CompanyName
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases AS DBs
WHERE @Anonymise = 0 AND DB_NAME() = DBs.Name

-- Anonymise site details for demo purposes if we need to
UPDATE #SitesList
SET  CompanyName = WebDemoSites.CompanyName,
	SubCompanyName = WebDemoSites.SubCompanyName,
	SiteID = 'pub' + CAST(Counter AS VARCHAR),
	[Name] = WebDemoSites.[SiteName],
	Street = WebDemoSites.Street,
	Town = WebDemoSites.Town,
	County = '',
	PostCode = WebDemoSites.PostCode,
	HasInternalSales = 1,
	RMName = 'TopMan ' + CAST(RMID AS VARCHAR),
	BDMName = 'MiddleMan ' + CAST(BDMID AS VARCHAR),
	SiteArea = 'Area ' + CAST(Counter AS VARCHAR)
FROM [SQL1\SQL1].ServiceLogger.dbo.WebDemoSites AS WebDemoSites
WHERE	@Anonymise = 1
	AND Counter = WebDemoSites.CounterID

-- If the user has a Locale forced, then substitute that now
UPDATE #SitesList
SET Locale = Users.LanguageOverride
FROM Users
WHERE Users.ID = @UserID
	AND Users.LanguageOverride IS NOT NULL

-- If the anonymised site details list doesn't have enough entries, strip all untouched sites for privacy reasons
DELETE FROM #SitesList
WHERE	SiteID NOT LIKE 'pub%'
	AND RMName NOT LIKE 'TopMan%'
	AND BDMName NOT LIKE 'MiddleMan%'
	AND SiteArea NOT LIKE 'Area%'
	AND @Anonymise = 1

UPDATE #SitesList
SET CompanyName = 'Fake PubCo Ltd'
WHERE @Anonymise = 1

-- Return site list for user (could be pretend, could be real)
SELECT	CompanyName,
	SubCompanyName,
	AuditedUpTo,
	EDISID,
	SiteID,
	[Name],
	Street,
	Town,
	PostCode,
	LastDownload,
	RMName,
	BDMName,
	LatestSalesDate,
	HasAnySales,
	SiteOnline,
	HasInternalSales,
	Locale,
	SiteArea,
	LicenseeLogins,
	LicenseeLatestLoginTime,
	StatusPouringYield,
	CommentPouringYield,
	StatusTillYield,
	CommentTillYield,
	StatusCleaning,
	CommentCleaning,
	StatusAlarm,
	StatusDeliveries,
	ISNULL(CommentDeliveries, '') AS CommentDeliveries,
	RankingCellarTemperature,
	RankingLineCleaning,
	RankingPouringYield,
	RankingRemoteCooling,
	RankingTemperature,
	RankingThroughput,
	RankingTillYield,
	RankingVariance,
	DateTimePouringYield,
	DateTimeTillYield,
	DateTimeCleaning,
	DateTimeDeliveries,
	TemperatureUnit,
	SiteLive,
	IsIDraught,
	HasEquipment,
	SmallVolumeUnit,
	LargeVolumeUnit,
	ContainerVolumeUnit,
	DrinkActionID,
	IsVRSMember,
	Auditor,
	HasLatestData,
	SiteGroupID,
	Club,
	RetailCashValue,
	OperationalCashValue,
	LowVolumeThreshold,
	ISNULL(RSICustomer, '') AS RSICustomer,
	SiteRankingEquipmentAmbient,
	SiteRankingEquipmentRecirc,
	SiteRankingCleaning,
	SiteRankingCleaningKeg,
	SiteRankingCleaningCask,
	SiteRankingThroughput,
	SiteRankingThroughputKeg,
	SiteRankingThroughputCask,
	SiteRankingTemperature,
	SiteRankingTemperatureKeg,
	SiteRankingTemperatureCask,
	SiteRankingPouringYield,
	SiteRankingPouringYieldKeg,
	SiteRankingPouringYieldCask,
	SiteRankingTillYield,
	SiteRankingTillYieldKeg,
	SiteRankingTillYieldCask,
	County,
	SystemTypeID,
	IncludeCleaningWasteInOverallYield
FROM #SitesList
ORDER BY [Name]

DROP TABLE #SC
DROP TABLE #WebSiteSessions
DROP TABLE #SitesList


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserSiteList] TO PUBLIC
    AS [dbo];

