CREATE PROCEDURE [neo].[GetCustomerSitesAndExceptionsForUserCalendar]
(
       @UserID     INT,
       @TradingDate DATETIME,
    @EDISID     INT = NULL
)
AS

/* for testing purposes only */
--DECLARE @UserID     INT = 4821
/* for testing purposes only */

DECLARE @DatabaseID         INT
DECLARE @ServerName         VARCHAR(255)
DECLARE @DatabaseName       VARCHAR(255)
DECLARE @CompanyName        VARCHAR(255)

-- User Conditions
DECLARE @Anonymise             BIT -- 0 = Identifying Site details presented as-is; 1 = Identifying Site details are replaced
DECLARE @UserHasAllSites   BIT -- 0 = Sites assigned to User via UserSites table; 1 = User automatically has access to all non-hidden Sites
DECLARE @WebActive          BIT -- 0 = User cannot log into any website; 1 = User can log as normal
DECLARE @Expired            BIT -- 0 = User can log on as normal; 1 = User has been deactivated due to inactivity
DECLARE @Deleted            BIT -- 0 = User can log on as normal; 1 = User has been deleted and cannot be used for any purpose

-- Retrieve general customer database details from the Logger database
SELECT
    @DatabaseID = EDISDatabases.ID,
    @ServerName = EDISDatabases.[Server],
    @DatabaseName = EDISDatabases.Name,
    @CompanyName = EDISDatabases.CompanyName
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.EDISDatabases
JOIN (  SELECT CAST(Configuration.PropertyValue AS INT) AS Value
        FROM dbo.Configuration
        WHERE Configuration.PropertyName = 'Service Owner ID'
    ) AS LoggerID ON EDISDatabases.ID = LoggerID.Value  -- Allows us to differentiate between identically named Databases (primarily a test server concern)
CROSS APPLY (   SELECT CAST(Configuration.PropertyValue AS BIT) AS Value
                FROM dbo.Configuration
                WHERE Configuration.PropertyName = 'WebAccessEnabled'
    ) AS WebEnabled
WHERE Name = DB_NAME()
AND EDISDatabases.[Enabled] = 1         -- Database is Enabled for general use
AND EDISDatabases.BuildWebUsers = 1     -- Web Site access is Enabled on Logger (this toggles a SQL Job which consolidates Web Site Users hourly)
AND WebEnabled.Value = 1                -- Web Site access is Enabled (legacy database setting)

-- What special conditions does the user have?
SELECT 
    @UserHasAllSites = UserTypes.AllSitesVisible, 
    @Anonymise = Users.Anonymise,
    @WebActive = Users.WebActive,
    @Expired = CASE WHEN (LastWebsiteLoginDate >= DATEADD(d, -90, GETDATE()) OR NeverExpire = 1) THEN 0 ELSE 1 END,
    @Deleted = Users.Deleted
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE Users.ID = @UserID

IF @Deleted = 0 AND @Expired = 0 AND @WebActive = 1
BEGIN
    DECLARE @UserSites TABLE ([Server] VARCHAR(255),
            DatabaseName VARCHAR(255),
            DatabaseID INT,
            UserID INT ,
            EDISID INT,
            SiteID VARCHAR(255),
                     CompanyName VARCHAR(255),
                     OwnerName VARCHAR(255),
                     Name VARCHAR(255),
                     Address1 VARCHAR(255),
                     Town VARCHAR(255),
                     PostCode  VARCHAR(255),
                     SmallUnitType VARCHAR(255))

    -- Site Conditions
    --  Must be a Primary Site
    --  Must Not Be Disposed

    IF @UserHasAllSites = 0
    BEGIN
        -- Read from User Sites
              INSERT INTO @UserSites
        SELECT
            @ServerName AS [Server],
            @DatabaseName AS DatabaseName,
            @DatabaseID AS DatabaseID,
            @UserID AS UserID,
            Sites.EDISID,
            Sites.SiteID,
            @CompanyName AS CompanyName,
            Owners.Name AS OwnerName,
            Sites.Name,
            Sites.Address1,
            CASE WHEN LEN(Sites.Address3) = 0 AND LEN(Sites.Address4) = 0 
                 THEN Sites.Address2
                          WHEN LEN(Sites.Address3) = 0 
                 THEN Sites.Address4
                          ELSE Sites.Address3
            END AS Town,
            Sites.PostCode,
            ISNULL(SmallUnit.Value, 'Default') AS SmallUnitType
        FROM dbo.Sites
        JOIN dbo.Owners ON Sites.OwnerID = Owners.ID
        JOIN dbo.UserSites ON Sites.EDISID = UserSites.EDISID AND UserID = @UserID AND @UserHasAllSites = 0
        LEFT JOIN ( SELECT SiteProperties.EDISID, SiteProperties.Value
                    FROM dbo.Properties
                    JOIN dbo.SiteProperties ON Properties.ID = SiteProperties.PropertyID
                    WHERE Properties.Name = 'Small Unit'
            ) AS SmallUnit ON Sites.EDISID = SmallUnit.EDISID
        LEFT JOIN ( SELECT SiteGroupSites.EDISID
                    FROM dbo.SiteGroups
                    JOIN dbo.SiteGroupSites ON SiteGroups.ID = SiteGroupSites.SiteGroupID
                    WHERE SiteGroups.TypeID = 1 -- Multi-Cellar
                    AND SiteGroupSites.IsPrimary != 1
            ) AS NonPrimary ON Sites.EDISID = NonPrimary.EDISID
        LEFT JOIN ( SELECT SiteProperties.EDISID
                    FROM dbo.Properties
                    JOIN dbo.SiteProperties ON Properties.ID = SiteProperties.PropertyID
                    WHERE Properties.Name = 'Disposed Status' 
                    AND LOWER(SiteProperties.Value) = 'yes'
            ) AS Disposed ON Sites.EDISID = Disposed.EDISID
        WHERE Sites.Hidden = 0
        AND Disposed.EDISID IS NULL
        AND NonPrimary.EDISID IS NULL
        AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
    END
    ELSE IF @UserHasAllSites = 1
    BEGIN
        -- Read from Sites direct
              INSERT INTO @UserSites
        SELECT
            @ServerName AS [Server],
            @DatabaseName AS DatabaseName,
            @DatabaseID AS DatabaseID,
            @UserID AS UserID,
            Sites.EDISID,
            Sites.SiteID,
            @CompanyName AS CompanyName,
            Owners.Name AS OwnerName,
            Sites.Name,
            Sites.Address1,
            CASE WHEN LEN(Sites.Address3) = 0 AND LEN(Sites.Address4) = 0 
                 THEN Sites.Address2
                          WHEN LEN(Sites.Address3) = 0 
                 THEN Sites.Address4
                          ELSE Sites.Address3
            END AS Town,
            Sites.PostCode,
            ISNULL(SmallUnit.Value, 'Default') AS SmallUnitType
        FROM dbo.Sites
        JOIN dbo.Owners ON Sites.OwnerID = Owners.ID
        LEFT JOIN ( SELECT SiteProperties.EDISID, SiteProperties.Value
                    FROM dbo.Properties
                    JOIN dbo.SiteProperties ON Properties.ID = SiteProperties.PropertyID
                    WHERE Properties.Name = 'Small Unit'
            ) AS SmallUnit ON Sites.EDISID = SmallUnit.EDISID
        LEFT JOIN ( SELECT SiteGroupSites.EDISID
                    FROM SiteGroups
                    JOIN SiteGroupSites ON SiteGroups.ID = SiteGroupSites.SiteGroupID
                    WHERE SiteGroups.TypeID = 1 -- Multi-Cellar
                    AND SiteGroupSites.IsPrimary != 1
            ) AS NonPrimary ON Sites.EDISID = NonPrimary.EDISID
        LEFT JOIN ( SELECT SiteProperties.EDISID
                    FROM Properties
                    JOIN SiteProperties ON Properties.ID = SiteProperties.PropertyID
                    WHERE Properties.Name = 'Disposed Status' 
                    AND LOWER(SiteProperties.Value) = 'yes'
            ) AS Disposed ON Sites.EDISID = Disposed.EDISID
        WHERE Sites.Hidden = 0
        AND Disposed.EDISID IS NULL
        AND NonPrimary.EDISID IS NULL
        AND (@EDISID IS NULL OR Sites.EDISID = @EDISID)
    END
       
       SELECT @DatabaseID, se.EDISID, se.ID, se.[Type], se.[TypeID], ISNULL(setypes.ID, -1) as ExceptionId,
              se.TradingDate, se.ShiftStart, se.ShiftEnd,
              se.Value, CAST(se.LowThreshold AS VARCHAR) AS 'LowThreshold', CAST(se.HighThreshold AS VARCHAR) AS 'HighThreshold'
       FROM SiteExceptions se
              LEFT JOIN SiteExceptionTypes AS setypes ON setypes.[ID] = se.[TypeID]
       WHERE 
              EDISID IN (SELECT EDISID FROM @UserSites)
              AND se.TradingDate >= CONVERT(date, @TradingDate)
       ORDER BY se.TradingDate ASC

END