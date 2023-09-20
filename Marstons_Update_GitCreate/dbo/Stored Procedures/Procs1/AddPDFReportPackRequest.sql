



CREATE PROCEDURE [dbo].[AddPDFReportPackRequest]
(
	-- This stored procedure is called by iDraughtWebSiteLib (the app class)
	-- Usually from the BMS web site, when a user requests a 'pack' email

	@SubmittedBy	VARCHAR(100),
	@UserID			INT,
	@EmailAddress	VARCHAR(100),
	@URL			TEXT
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @OwnerID INT
DECLARE @UserHasAllSites   BIT

SELECT @UserHasAllSites = UserTypes.AllSitesVisible
FROM Users
JOIN UserTypes ON UserTypes.ID = Users.UserType
WHERE Users.ID = @UserID

-- Have a stab at guessing my OwnerID - note the fall-back of MIN(ID) should there be multiple...
-- & the data auditor - again, spot the fall-back
DECLARE @Auditor VARCHAR(200)

IF @UserHasAllSites = 1
BEGIN
	SELECT TOP 1 @OwnerID = Owners.ID, @Auditor = Sites.SiteUser
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.ID
	WHERE Hidden = 0
END
ELSE
BEGIN
	SELECT TOP 1 @OwnerID = Owners.ID, @Auditor = Sites.SiteUser
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.ID
	JOIN UserSites ON Sites.EDISID = UserSites.EDISID
	WHERE Hidden = 0
END

IF LEN(@Auditor) = 0
BEGIN
	SELECT @Auditor = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorName'
END

SET @Auditor = REPLACE(RIGHT(@Auditor,LEN(@Auditor)-CHARINDEX('\',@Auditor)), '.', ' ')

DECLARE @AuditorEmail VARCHAR(250)
SET @AuditorEmail = REPLACE(@Auditor, ' ', '.') + '@brulines.com'

-- dd-mm-yy format for the filename
DECLARE @Requested DATETIME = GETDATE()

-- Now put in queue
INSERT INTO [EDISSQL1\SQL1].ServiceLogger.dbo.PDFRequests
(SubmittedBy, UserName, EmailAddress, RequestDate, DatabaseID, Url, FileName, PDFType, UserID, EmailLink, EmailReplyTo, UserTypeID, EmailSubject, EmailBody)
SELECT	@SubmittedBy,
		Users.UserName,
		@EmailAddress,
		@Requested,
		@DatabaseID,
		@URL,
		'Brulines Report Pack %SUBMITTEDON%.pdf',
		3,
		@UserID,
		'',
		@AuditorEmail,
		Users.UserType,
		Owners.PDFReportPackSubject,
		REPLACE(Owners.PDFReportPackHTML, '%AUDITOR%', @Auditor)
FROM Users 
JOIN Owners ON Owners.ID = @OwnerID
WHERE Users.ID = @UserID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPDFReportPackRequest] TO PUBLIC
    AS [dbo];

