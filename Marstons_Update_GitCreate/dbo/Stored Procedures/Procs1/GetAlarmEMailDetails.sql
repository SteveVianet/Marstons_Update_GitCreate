CREATE PROCEDURE [dbo].[GetAlarmEMailDetails]
(
	@EDISID				INT
)
AS

SET NOCOUNT ON

DECLARE @AllAlertEmails		VARCHAR(8000)
DECLARE @AlertsOn			BIT = 0
DECLARE @AlertEmailOverride VARCHAR(8000)
DECLARE @AlertEmailCC		VARCHAR(8000)
DECLARE @AlertEmailReplyToOverride		VARCHAR(8000)
DECLARE @AlertCustomMessage		VARCHAR(1000)
DECLARE @PerSiteAuditor		BIT = 0
DECLARE @DatabaseID			INT
DECLARE @TimeZone			VARCHAR(100)

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

SET @AlertsOn = CASE WHEN CHARINDEX('@', @AllAlertEmails) > 0 THEN 1 ELSE 0 END

SELECT	Sites.EDISID,
		@AllAlertEmails AS AlertEMail,
		@AlertsOn AS AlertsOn,
		CASE	WHEN SiteLocations.International = 'en-US'
				THEN 'i-draft Alert: ' + Configuration.PropertyValue + ', ' + Sites.Name + ', ' + Sites.Address1 + ', ' + COALESCE(Sites.Address3, Sites.Address4)
				ELSE 'iDraught Alert: ' + Configuration.PropertyValue + ', ' + Sites.Name + ', ' + Sites.Address1 + ', ' + COALESCE(Sites.Address3, Sites.Address4)
		END AS AlertLabel,
		CASE	WHEN SiteLocations.International = 'en-US'
				THEN 'www.i-draft.com'
				ELSE 'www.idraught.com'
		END AS AlertLink,
		CASE	WHEN SiteLocations.International = 'en-US'
				THEN 1
				ELSE 0
		END AS ConvertToFarenheit,
		ISNULL(@AlertEmailCC, '') AS AlertEMailCC,
		CASE	WHEN @AlertEmailReplyToOverride IS NOT NULL
				THEN @AlertEmailReplyToOverride
				ELSE 
					CASE	WHEN @PerSiteAuditor = 1
							THEN REPLACE([dbo].[udfNiceName](Sites.SiteUser), ' ', '.') + '@vianetplc.com'
							ELSE (SELECT PropertyValue FROM Configuration WHERE PropertyName = 'AuditorEMail')
					END
		END AS AlertReplyTo,
		ISNULL(@AlertCustomMessage, '') AS AlertMessage,
		@TimeZone AS [TimeZone]
FROM Sites
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
LEFT OUTER JOIN (
	SELECT SiteProperties.EDISID, SiteProperties.Value AS International
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.Name = 'International'
) AS SiteLocations ON SiteLocations.EDISID = Sites.EDISID
WHERE (Sites.EDISID = @EDISID OR @EDISID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAlarmEMailDetails] TO PUBLIC
    AS [dbo];

