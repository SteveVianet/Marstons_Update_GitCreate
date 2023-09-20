
CREATE PROCEDURE AddWeeklySiteLevelReportRequest
	@EDISID				INT,
	@ToEmailOverride	VARCHAR(100) = NULL,
	@DateOverride		DATE = NULL
AS

SET NOCOUNT ON;

DECLARE @WeeklyReportDate DATE
IF @DateOverride IS NULL
BEGIN
	-- Default to yesterday
	SET @WeeklyReportDate = DATEADD(DAY, -1, GETDATE())
END
ELSE
BEGIN
	-- Use user-requested date
	SET @WeeklyReportDate = @DateOverride
END
DECLARE @DateStringForURL VARCHAR(20)
SET @DateStringForURL = CAST(DAY(@WeeklyReportDate) AS VARCHAR) + '-' + CAST(CONVERT(CHAR(3), @WeeklyReportDate, 0) AS VARCHAR) + '-' + CAST(YEAR(@WeeklyReportDate) AS VARCHAR)

DECLARE @DatabaseID INT
SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @DateStringForFilename VARCHAR(20)
SET @DateStringForFilename = REPLACE(CONVERT(VARCHAR(8),@WeeklyReportDate, 1), '/', '')

DECLARE @SiteReportWebsite VARCHAR(100)
SELECT @SiteReportWebsite = CAST(PropertyValue AS VARCHAR(200))
FROM Configuration
WHERE PropertyName = 'iDraught Weekly Site Report Application URL'

INSERT INTO [EDISSQL1\SQL1].ServiceLogger.dbo.PDFRequests
(SubmittedBy, UserName, EmailAddress, RequestDate, DatabaseID, Url, FileName, PDFType, UserID, EmailLink, EmailReplyTo, UserTypeID, EmailSubject, EmailBody)
SELECT	'Database Job',
		TenantUsers.UserName,
		CASE WHEN @WeeklyReportDate IS NOT NULL THEN @WeeklyReportDate ELSE TenantUsers.EMail END,
		GETDATE(),
		@DatabaseID,
		@SiteReportWebsite + '/Secure/ReportSiteSummary.aspx?From=' + @DateStringForURL + '&To=' + @DateStringForURL + '&ID=' + CAST(@DatabaseID AS VARCHAR) + '-' + CAST(Sites.EDISID AS VARCHAR) + '&u=' + CAST(TenantUsers.[Login] AS VARCHAR) + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), TenantUsers.[Password] + 'DGJRR'))), '0x', ''),
		'SiteLevelReport-' + REPLACE(Sites.Name, ' ', '') + '-' + @DateStringForFilename + '.pdf',
		6,
		TenantUsers.UserID,
		'http://app.idraught.com/Secure/Disclaimer.aspx?u=' + CAST(TenantUsers.[Login] AS VARCHAR) + '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), TenantUsers.[Password] + 'DGJRR'))), '0x', ''),
		CASE WHEN Locale = 'en-US' THEN 'ushelpdesk@vianetplc.com' ELSE 'idraughthelpdesk@vianetplc.com' END,
		TenantUsers.UserType,
		Owners.WeeklySiteReportSubject,
		Owners.WeeklySiteReportHTML
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
	AND WebActive = 1
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
AND (Sites.EDISID = @EDISID OR @EDISID IS NULL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWeeklySiteLevelReportRequest] TO PUBLIC
    AS [dbo];

