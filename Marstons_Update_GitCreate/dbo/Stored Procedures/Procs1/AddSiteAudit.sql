CREATE PROCEDURE [dbo].[AddSiteAudit]
(
	@EDISID		INT,
	@Comment	TEXT,
	@AuditType	INT = 1,
	@User		VARCHAR(255) = NULL,
	@Date		DATETIME = NULL
)

AS

SET NOCOUNT ON

IF (@User IS NOT NULL) OR (@Date IS NOT NULL)
BEGIN
	INSERT INTO SiteAudits
		(EDISID, UserName, [TimeStamp], Comment, AuditType)
	VALUES
		(@EDISID, @User, @Date, @Comment, @AuditType)	
END
ELSE
BEGIN
	INSERT INTO SiteAudits
		(EDISID, UserName, [TimeStamp], Comment, AuditType)
	VALUES
		(@EDISID, SUSER_SNAME(), GETDATE(), @Comment, @AuditType)
END

DECLARE @Quality BIT
DECLARE @OwnerID INT
DECLARE @SendScorecardEmail BIT = 0
DECLARE @UserID INT
DECLARE @IsSiteUsingExceptions BIT
DECLARE @AutoSendExceptions BIT

SELECT	@Quality = Quality, @OwnerID = OwnerID, @IsSiteUsingExceptions = UseExceptionReporting, @AutoSendExceptions = AutoSendExceptions
FROM Sites
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE EDISID = @EDISID

-- If it's an iDraught site and the audit comes from Lite then
-- check to send the iDraught scorecard e-mail
IF @Quality = 1 AND @AuditType = 10
BEGIN
	IF @OwnerID > 0
	BEGIN
		SELECT @SendScorecardEmail = SendScorecardEmail
		FROM Owners
		WHERE ID = @OwnerID
	
	END
	ELSE
	BEGIN
		SET @SendScorecardEmail = 0
		
	END

	IF @SendScorecardEmail = 1
	BEGIN
		DECLARE @ScorecardVersion INT
		
		SELECT @ScorecardVersion = CAST(PropertyValue AS INTEGER)
		FROM Configuration
		WHERE PropertyName = 'Scorecard Version'
	
		IF @ScorecardVersion = 1
		BEGIN
			-- Embedded-in-email scorecard
			SELECT @UserID = Users.ID
			FROM UserSites
			JOIN Users ON Users.ID = UserSites.UserID
			WHERE EDISID = @EDISID
			AND UserType IN (5, 6)
			AND WebActive = 1
			AND Deleted = 0
			AND (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR NeverExpire = 1)
			AND EMail <> ''
			AND ReceiveiDraughtScorecard = 1
			
			IF @UserID IS NOT NULL
			BEGIN
				INSERT INTO dbo.SiteScorecardEmails
				(EDISID, [Date], RecipientUserID)
				VALUES
				(@EDISID, GETDATE(), @UserID)
		
			END
		
		END
		ELSE IF @ScorecardVersion = 2
		BEGIN
			-- PDF Daily Scorecard
			EXEC AddScorecardDailyRequests @EDISID
			
		END
	
	END

	IF @IsSiteUsingExceptions = 1 AND @AutoSendExceptions = 1
	BEGIN
		EXEC AddSitePDFExceptionReport @EDISID
	END
	
END

DECLARE @DatabaseID INT
SELECT @DatabaseID = ID
FROM	[SQL1\SQL1].[ServiceLogger].[dbo].[EDISDatabases]
WHERE	Name = DB_NAME()

DECLARE @iDraught BIT = 0
IF @AuditType = 10
BEGIN
	SET @iDraught = 1
END

IF @AuditType = 1 OR @AuditType = 10
BEGIN
	EXEC [SQL1\SQL1].[Auditing].[dbo].[AcknowledgeSiteNotifications] @DatabaseID, @EDISID, @User, @iDraught
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteAudit] TO PUBLIC
    AS [dbo];

