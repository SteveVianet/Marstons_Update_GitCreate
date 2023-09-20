CREATE PROCEDURE [neo].[GetScheduleSites]
(
	@ScheduleID	INTEGER,
	@DoNotExtend	BIT = 0
)

AS

DECLARE @ExpiryDate DATETIME

SET NOCOUNT ON

DECLARE @DatabaseID         INT
DECLARE @ServerName         VARCHAR(255)
DECLARE @DatabaseName       VARCHAR(255)
DECLARE @CompanyName        VARCHAR(255)

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

IF @DoNotExtend = 0
BEGIN
	-- Get expiry date for selected schedule
	SELECT @ExpiryDate = ExpiryDate
	FROM Schedules
	WHERE [ID] = @ScheduleID

	-- If expiry date is set, then extend it to today+14 days
	IF NOT @ExpiryDate IS NULL
	BEGIN
		UPDATE Schedules
		SET ExpiryDate = DATEADD(d, 14, GETDATE())
		WHERE [ID] = @ScheduleID
	END
END

UPDATE Schedules
SET	UsedOn = GETDATE(),
	UsedBy = SUSER_SNAME()
WHERE [ID] = @ScheduleID

SELECT 
	@ServerName AS [ServerName],
    @DatabaseName AS DatabaseName,
    @DatabaseID AS DatabaseID,
    0 AS UserID,
    Sites.EDISID,
    Sites.SiteID,
    @CompanyName AS CompanyName,
    Owners.Name AS SubcompanyName,
    Sites.Name,
    Sites.Address1 AS Street,
    CASE WHEN LEN(Sites.Address3) = 0 AND LEN(Sites.Address4) = 0 
            THEN Sites.Address2
			WHEN LEN(Sites.Address3) = 0 
            THEN Sites.Address4
			ELSE Sites.Address3
    END AS Town,
    Sites.PostCode,
    ISNULL(SmallUnit.Value, 'Default') AS SmallVolumeUnit,
	Sites.SystemTypeID
FROM dbo.ScheduleSites
JOIN dbo.Sites ON Sites.EDISID = ScheduleSites.EDISID
JOIN dbo.Owners ON Sites.OwnerID = Owners.ID
LEFT JOIN ( SELECT SiteProperties.EDISID, SiteProperties.Value
                    FROM dbo.Properties
                    JOIN dbo.SiteProperties ON Properties.ID = SiteProperties.PropertyID
                    WHERE Properties.Name = 'Small Unit'
            ) AS SmallUnit ON Sites.EDISID = SmallUnit.EDISID
WHERE ScheduleID = @ScheduleID
ORDER BY Sites.SiteID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetScheduleSites] TO PUBLIC
    AS [dbo];

