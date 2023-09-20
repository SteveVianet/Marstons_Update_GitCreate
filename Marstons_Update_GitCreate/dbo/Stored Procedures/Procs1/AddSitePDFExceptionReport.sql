
CREATE PROCEDURE [dbo].[AddSitePDFExceptionReport]
(
	@EDISID INT
)
AS

SET NOCOUNT ON

DECLARE @ReportFrom DATETIME
DECLARE @ReportTo DATETIME
DECLARE @SubmittedBy VARCHAR(100)
DECLARE @TenantUserID INT
DECLARE @TenantUserLogin VARCHAR(100)
DECLARE @TenantUserPassword VARCHAR(100)
DECLARE @EmailAddress VARCHAR(MAX) = ''
DECLARE @URL VARCHAR(MAX)
DECLARE @DatabaseID INT
DECLARE @ReportFirstDayOfWeek INT
DECLARE @EmailID INT
DECLARE @Today DATE

SET @Today = CAST(GETDATE() AS DATE)

SELECT @ReportFirstDayOfWeek = ReportingFirstDayOfWeek
FROM Owners
JOIN Sites ON Sites.OwnerID = Owners.ID AND Sites.EDISID = @EDISID

SELECT	@ReportFrom = DATEADD(DAY, -7, MAX(CalendarDate)),
		@ReportTo = DATEADD(DAY, 6, DATEADD(DAY, -7, MAX(CalendarDate)))
FROM Calendar
WHERE CalendarDate <= @Today
AND [DayOfWeek] = @ReportFirstDayOfWeek

SET @SubmittedBy = dbo.udfNiceName(SUSER_NAME())

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @TenantUserID = MAX(Users.ID)
FROM Users
JOIN UserSites ON UserSites.UserID = Users.ID
WHERE EDISID = @EDISID
AND UserType IN (5, 6)
AND EMail <> ''
AND WebActive = 1
AND (NeverExpire = 1 OR (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR LastWebsiteLoginDate IS NULL))

SELECT	@TenantUserLogin = [Login], 
		@TenantUserPassword = [Password]
FROM Users
WHERE ID = @TenantUserID

SELECT @EmailAddress = @EmailAddress + Email + ';'
FROM SiteExceptionEmailAddresses
WHERE EDISID = @EDISID

IF @EmailAddress IS NULL
BEGIN
	SET @EmailAddress = ''
END
ELSE
BEGIN
	IF RIGHT(@EmailAddress, 1) = ';'
	BEGIN
		SET @EmailAddress = LEFT(@EmailAddress, LEN(@EmailAddress) - 1)
	END

END

SELECT @URL = PropertyValue +
	   '/secure/ReportSiteSummary.aspx?From=' + REPLACE(CONVERT(CHAR(11), @ReportFrom, 106), ' ', '-') +
	   '&To=' + REPLACE(CONVERT(CHAR(11), @ReportTo, 106), ' ', '-') +
	   '&ID=' + CAST(@DatabaseID AS VARCHAR) + '-' + CAST(@EDISID AS VARCHAR) +
	   '&u=' + @TenantUserLogin +
	   '&pwd=' + REPLACE(master.sys.fn_varbintohexstr(HashBytes('MD5', CONVERT(varchar(4000), @TenantUserPassword + 'DGJRR'))), '0x', '') +
	   '&ResetSession=True'
FROM Configuration
WHERE PropertyName = 'iDraught Weekly Site Report Application URL'

-- Add to PDF queue (on EDISSQL1\SQL1 ServiceLogger database)
EXEC dbo.AddPDFExceptionReport @SubmittedBy, @TenantUserID, @EmailAddress, @URL, 1

-- Adds record of email to SiteExceptionEmails table
EXEC dbo.AddSiteExceptionEmail @EmailAddress, 'Weekly Site Report', @URL, @EmailID OUTPUT

-- Adds report request into SiteExceptions table to show report was sent to site
EXEC dbo.AddSiteException @EDISID, 'Weekly Site Report', @Today, 0, NULL, NULL, @ReportFrom, @ReportTo, @EmailID

UPDATE SiteExceptionEmails
SET EmailDate = GETDATE()
WHERE ID = @EmailID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSitePDFExceptionReport] TO PUBLIC
    AS [dbo];

