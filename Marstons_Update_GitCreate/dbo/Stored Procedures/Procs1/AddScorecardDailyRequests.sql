
CREATE PROCEDURE [dbo].[AddScorecardDailyRequests]
(
	@EDISID				INT = NULL,
	@ToEmailOverride	VARCHAR(100) = NULL,
	@DateOverride		DATE = NULL
)
AS

SET NOCOUNT ON

DECLARE @DailyScorecardDate DATE
IF @DateOverride IS NULL
BEGIN
	-- Default to yesterday
	SET @DailyScorecardDate = DATEADD(DAY, -1, GETDATE())
END
ELSE
BEGIN
	-- Use user-requested date
	SET @DailyScorecardDate = @DateOverride
END
DECLARE @DateStringForURL VARCHAR(20)
SET @DateStringForURL = CAST(DAY(@DailyScorecardDate) AS VARCHAR) + '-' + CAST(CONVERT(CHAR(3), @DailyScorecardDate, 0) AS VARCHAR) + '-' + CAST(YEAR(@DailyScorecardDate) AS VARCHAR)

-- MMddyy format for the filename
DECLARE @DateStringForFilename VARCHAR(20)
SET @DateStringForFilename = REPLACE(CONVERT(VARCHAR(8),@DailyScorecardDate, 1), '/', '')

DECLARE @DatabaseID INT
SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @ScorecardWebsite VARCHAR(100)
SELECT @ScorecardWebsite = CAST(PropertyValue AS VARCHAR(200))
FROM Configuration
WHERE PropertyName = 'iDraught Scorecard Application URL'

INSERT INTO [EDISSQL1\SQL1].ServiceLogger.dbo.PDFRequests
(SubmittedBy, UserName, EmailAddress, RequestDate, DatabaseID, Url, FileName, PDFType, UserID, EmailLink, EmailReplyTo, UserTypeID, EmailSubject, EmailBody)
SELECT	'Database Job',
		TenantUsers.UserName,
		CASE WHEN @ToEmailOverride IS NOT NULL THEN @ToEmailOverride ELSE TenantUsers.EMail END,
		GETDATE(),
		@DatabaseID,
		@ScorecardWebsite + '/Secure/ScorecardExport.aspx?From=' + @DateStringForURL + '&To=' + @DateStringForURL + '&ID=' + CAST(@DatabaseID AS VARCHAR) + '-' + CAST(Sites.EDISID AS VARCHAR) + '&u=' + CAST(TenantUsers.[Login] AS VARCHAR) + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), TenantUsers.[Password] + 'DGJRR'))), '0x', ''),
		REPLACE(Sites.Name, ' ', '') + '-' + @DateStringForFilename + '.pdf',
		5,
		TenantUsers.UserID,
		'http://app.idraught.com/Secure/Disclaimer.aspx?u=' + CAST(TenantUsers.[Login] AS VARCHAR) + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), TenantUsers.[Password] + 'DGJRR'))), '0x', ''),
		CASE WHEN Locale = 'en-US' THEN 'ushelpdesk@vianetplc.com' ELSE 'idraughthelpdesk@vianetplc.com' END,
		TenantUsers.UserType,
		Owners.DailyScorecardSubject,
		Owners.DailyScorecardHTML
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
JOIN
(
	SELECT	Users.ID AS UserID,
			Users.UserName,
			UserSites.EDISID, 
			Users.EMail,
			Users.[Login],
			Users.[Password],
			Users.ReceiveiDraughtScorecard,
			Users.UserType
	FROM Users
	JOIN UserSites ON UserSites.UserID = Users.ID
	WHERE UserType IN (5, 6)
	AND (EMail <> '' OR @ToEmailOverride IS NOT NULL)
	AND WebActive = 1
	AND (NeverExpire = 1 OR (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR LastWebsiteLoginDate IS NULL))
	AND ReceiveiDraughtScorecard = 1
) AS TenantUsers ON TenantUsers.EDISID = Sites.EDISID
LEFT JOIN
(
	SELECT	EDISID, 
			SiteProperties.Value AS Locale
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE Properties.Name = 'International'
) AS SiteLocale ON SiteLocale.EDISID = Sites.EDISID
WHERE Hidden = 0
AND Quality = 1
AND Owners.SendScorecardEmail = 1
AND (Sites.EDISID = @EDISID OR @EDISID IS NULL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddScorecardDailyRequests] TO PUBLIC
    AS [dbo];

