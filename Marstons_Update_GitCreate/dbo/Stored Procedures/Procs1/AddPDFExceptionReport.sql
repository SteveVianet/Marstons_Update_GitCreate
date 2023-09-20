
CREATE PROCEDURE [dbo].[AddPDFExceptionReport]
(

	@SubmittedBy	VARCHAR(100),
	@UserID			INT,
	@EmailAddress	VARCHAR(MAX),
	@URL			TEXT,
	@IsSiteReport	BIT
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
--DECLARE @Auditor VARCHAR(200)

IF @UserHasAllSites = 1
BEGIN
	SELECT TOP 1 @OwnerID = Owners.ID
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.ID
	WHERE Hidden = 0
END
ELSE
BEGIN
	SELECT TOP 1 @OwnerID = Owners.ID
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.ID
	JOIN UserSites ON Sites.EDISID = UserSites.EDISID
	WHERE Hidden = 0
END

DECLARE @ReplyToEmail VARCHAR(250)

SELECT @ReplyToEmail = CAST(PropertyValue AS VARCHAR(250))
FROM Configuration
WHERE PropertyName = 'iDraught Helpdesk Email Address'

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
		CASE WHEN @IsSiteReport = 1 THEN 'WeeklySite-%USERNAME%-%SUBMITTEDON%.pdf' ELSE 'WeeklyExec-%USERNAME%-%SUBMITTEDON%.pdf' END,
		CASE WHEN @IsSiteReport = 1 THEN 7 ELSE 6 END,
		@UserID,
		'',
		@ReplyToEmail,
		Users.UserType,
		CASE WHEN @IsSiteReport = 1 THEN Owners.WeeklySiteReportSubject ELSE Owners.WeeklyExecReportSubject END,
		CASE WHEN @IsSiteReport = 1 THEN Owners.WeeklySiteReportHTML ELSE Owners.WeeklyExecReportHTML END
FROM Users 
JOIN Owners ON Owners.ID = @OwnerID
WHERE Users.ID = @UserID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPDFExceptionReport] TO PUBLIC
    AS [dbo];

