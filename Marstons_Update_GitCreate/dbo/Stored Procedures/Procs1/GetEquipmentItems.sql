
CREATE PROCEDURE [dbo].[GetEquipmentItems]
(
	@EDISID				INT,
	@EQUIPMENTTYPE		INT = NULL,
	@SlaveID			INT = NULL,
	@IsDigital			BIT = NULL,
	@OnlyInUse			BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @AllAlertEmails		VARCHAR(8000)
DECLARE @AlertsOn			BIT = 0
DECLARE @ExceptionsOn		BIT = 0
DECLARE @AlertEmailOverride VARCHAR(8000)
DECLARE @AlertEmailCC		VARCHAR(8000)
DECLARE @AlertEmailReplyToOverride		VARCHAR(8000)
DECLARE @AlertEmailReplyTo		VARCHAR(8000)
DECLARE @AlertCustomMessage		VARCHAR(1000)
DECLARE @PerSiteAuditor		BIT = 0
DECLARE @DatabaseID			INT
DECLARE @TimeZone			VARCHAR(100)
DECLARE @AlertsVersion		INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @PerSiteAuditor = [MultipleAuditors] 
FROM [EDISSQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases]
WHERE ID = @DatabaseID

SELECT @AlertEmailOverride = PropertyValue
FROM Configuration
WHERE PropertyName = 'Alert Email To Override'

SELECT @AlertCustomMessage = PropertyValue
FROM Configuration
WHERE PropertyName = 'Alert Email Message'

SELECT @TimeZone = Value
FROM SiteProperties
WHERE PropertyID IN (SELECT ID FROM Properties WHERE Name = 'TimeZone')
AND EDISID = @EDISID

IF CHARINDEX('@', @AlertEmailOverride) > 0
BEGIN
	SET @AllAlertEmails = @AlertEmailOverride
END
ELSE
BEGIN
	SELECT @AllAlertEmails = COALESCE(@AllAlertEmails, '') + EMail + '; '
	FROM (
		SELECT  UserSites.EDISID,
					UserSites.UserID,
					UserName,
					EMail
			FROM UserSites
			JOIN Users ON Users.[ID] = UserSites.UserID
			WHERE	UserSites.EDISID = @EDISID
					AND SendEMailAlert = 1
	) AS AlertEmailAddresses
END

SELECT @AlertEmailCC = PropertyValue
FROM Configuration
WHERE PropertyName = 'Alert Email CC Recipients'

SELECT @AlertEmailReplyToOverride = PropertyValue
FROM Configuration
WHERE PropertyName = 'Alert Email Reply To'

SELECT @AlertsVersion = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Alerts Version'

IF CHARINDEX('@', @AlertEmailReplyToOverride) > 0
BEGIN
	SET @AlertEmailReplyTo = @AlertEmailReplyToOverride
END
ELSE
BEGIN
	IF @PerSiteAuditor = 1
	BEGIN
		SELECT @AlertEmailReplyTo = REPLACE([dbo].[udfNiceName](Sites.SiteUser), ' ', '.') + '@vianetplc.com'
		FROM Sites
		WHERE EDISID = @EDISID
	END
	ELSE
	BEGIN
		SELECT @AlertEmailReplyTo = PropertyValue
		FROM Configuration
		WHERE PropertyName = 'AuditorEMail'
	END
END

-- Note that this will effectively prevent alerts being raised+sent if there is
-- no configured 'alert user' (with email address) for the site.
SET @AlertsOn = CASE WHEN CHARINDEX('@', @AllAlertEmails) > 0 THEN 1 ELSE 0 END

-- If no 'alert user' then check the exceptions setup
IF @AlertsOn = 0
BEGIN
	SELECT @AlertsOn = Owners.UseExceptionReporting
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.ID
	WHERE EDISID = @EDISID

END

SELECT	EquipmentItems.[ID],
		0 AS SlaveID,
	   	0 AS IsDigital,
		InputID,
		LocationID,
		EquipmentTypeID,
		EquipmentSubTypes.ID AS EquipmentSubTypeID,
		CASE	WHEN EquipmentItems.[Description] <> ''
				THEN EquipmentItems.[Description]
				ELSE EquipmentTypes.[Description]
		END AS [Description],
		ValueSpecification,
		ValueTolerance,
		InUse,
		ISNULL(AlarmThreshold, EquipmentTypes.DefaultAlarmThreshold) AS AlarmThreshold,
		ISNULL(ValueLowSpecification, EquipmentTypes.DefaultLowSpecification) AS ValueLowSpecification,
		ISNULL(ValueHighSpecification, EquipmentTypes.DefaultHighSpecification) AS ValueHighSpecification,
		ISNULL(LowAlarmThreshold, EquipmentTypes.DefaultLowAlarmThreshold) AS LowAlarmThreshold,
		ISNULL(HighAlarmThreshold, EquipmentTypes.DefaultHighAlarmThreshold) AS HighAlarmThreshold,
		Locations.Description AS LocationDescription, 
		EquipmentTypes.Description AS EquipmentTypeDescription,
		EquipmentSubTypes.Description AS EquipmentSubTypeDescription,
		@AllAlertEmails AS AlertEMail,
		@AlertsOn AS AlertsOn,
		LastAlarmingReading,
		
		CASE WHEN @AlertsVersion = 1 THEN 
			(CASE WHEN SiteLocations.International = 'en-US' 
				  THEN 'i-draft Alert: ' + Configuration.PropertyValue + ', ' + Sites.Name + ', ' + Sites.Address1 + ', ' + COALESCE(Sites.Address3, Sites.Address4)
				  ELSE 'iDraught Alert: ' + Configuration.PropertyValue + ', ' + Sites.Name + ', ' + Sites.Address1 + ', ' + COALESCE(Sites.Address3, Sites.Address4)
			 END)
		WHEN @AlertsVersion = 2 
			THEN 'iDraught Alert: ' + Configuration.PropertyValue + ', ' + Sites.Name + ', ' + Sites.Address1 + ', ' + COALESCE(Sites.Address3, Sites.Address4)
		ELSE '' END AS AlertLabel,
		
		CASE WHEN @AlertsVersion = 1 THEN
		(CASE	WHEN SiteLocations.International = 'en-US'
				THEN 'www.i-draft.com'
				ELSE 'www.idraught.com'
		END)
		WHEN @AlertsVersion = 2
			THEN 'www.idraught.com'
		ELSE '' END AS AlertLink,
		
		AlarmStartTime,
		AlarmEndTime,
		CASE	WHEN SiteLocations.International = 'en-US'
				THEN 1
				ELSE 0
		END AS ConvertToFarenheit,
		ISNULL(@AlertEmailCC, '') AS AlertEMailCC,
		ISNULL(@AlertEmailReplyTo, '') AS AlertReplyTo,
		ISNULL(@AlertCustomMessage, '') AS AlertMessage,
		@TimeZone AS [TimeZone],
		AlarmStatus
FROM EquipmentItems
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentItems.EquipmentTypeID
JOIN Locations ON Locations.ID = EquipmentItems.LocationID
JOIN EquipmentSubTypes ON EquipmentSubTypes.ID = EquipmentTypes.EquipmentSubTypeID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
JOIN Sites ON Sites.EDISID = EquipmentItems.EDISID
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS International
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'International'
) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID
WHERE EquipmentItems.EDISID = @EDISID
AND (EquipmentTypeID = @EQUIPMENTTYPE OR @EQUIPMENTTYPE IS NULL)
AND (InUse = 1 OR @OnlyInUse = 0)
ORDER BY EquipmentItems.InputID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEquipmentItems] TO PUBLIC
    AS [dbo];

