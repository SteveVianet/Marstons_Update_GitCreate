CREATE PROCEDURE [dbo].[AddAutoAuditEmailRequest]
	@UserID				INT,
	@SubmittedBy		VARCHAR(100),
	@ToEmailOverride	VARCHAR(100) = NULL
	
AS

SET NOCOUNT ON;

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
	WHERE Hidden = 0 AND UserSites.UserID = @UserID
END

IF LEN(@Auditor) = 0
BEGIN
	SELECT @Auditor = PropertyValue
	FROM Configuration
	WHERE PropertyName = 'AuditorName'
END

DECLARE @AuditorEmail VARCHAR(250)
SET @AuditorEmail = REPLACE(RIGHT(@Auditor,LEN(@Auditor)-CHARINDEX('\',@Auditor)), ' ', '.') + '@brulines.com'

INSERT INTO [EDISSQL1\SQL1].ServiceLogger.dbo.PDFRequests
(SubmittedBy, UserName, EmailAddress, RequestDate, DatabaseID, Url, FileName, PDFType, UserID, EmailLink, EmailReplyTo, UserTypeID, EmailSubject, EmailBody)
SELECT	@SubmittedBy,
		Users.UserName,
		CASE WHEN @ToEmailOverride IS NOT NULL THEN @ToEmailOverride ELSE Users.EMail END,
		GETDATE(),
		@DatabaseID,
		'',
		'',
		4,
		Users.ID,
		'',
		@AuditorEmail,
		Users.UserType,
		Owners.DispenseMonitoringDataSubject,
		Owners.DispenseMonitoringDataHTML
FROM Users
JOIN Owners ON Owners.ID = @OwnerID
WHERE Users.ID = @UserID
AND (EMail <> '' OR @ToEmailOverride IS NOT NULL)
AND WebActive = 1
AND (NeverExpire = 1 OR (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR LastWebsiteLoginDate IS NULL))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddAutoAuditEmailRequest] TO PUBLIC
    AS [dbo];

