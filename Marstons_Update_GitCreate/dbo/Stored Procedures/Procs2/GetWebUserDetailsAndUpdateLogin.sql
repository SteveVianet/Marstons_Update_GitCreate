

CREATE PROCEDURE [dbo].[GetWebUserDetailsAndUpdateLogin]
(
	@UserID	INT
)
AS

SET NOCOUNT ON

DECLARE @LastWebsiteLoginDate	DATETIME
DECLARE @UserName 				VARCHAR(255)
DECLARE @Anonymise 				BIT
DECLARE @UserTypeID				INT
DECLARE @UserType				VARCHAR(255)
DECLARE @EMail					VARCHAR(255)
DECLARE @AllSitesVisible		BIT

DECLARE @YieldThreshold FLOAT

SELECT @UserName  = UserName,
	@LastWebsiteLoginDate = LastWebsiteLoginDate,
	@Anonymise = Anonymise,
	@UserTypeID = UserType,
	@UserType = dbo.UserTypes.Description,
	@EMail = EMail,
	@AllSitesVisible = AllSitesVisible
FROM dbo.Users
JOIN dbo.UserTypes ON dbo.UserTypes.ID = dbo.Users.UserType
WHERE dbo.Users.[ID] = @UserID

UPDATE dbo.Users
SET LastWebsiteLoginDate = GETDATE()
WHERE [ID] = @UserID

DECLARE @UserSiteCount INT
DECLARE @UserIDraughtSiteCount INT
DECLARE @UserBMSSiteCount INT

IF @AllSitesVisible = 1
BEGIN
    SELECT @UserIDraughtSiteCount = COUNT(CASE WHEN Sites.Quality = 1 THEN 1 ELSE NULL END),
           @UserBMSSiteCount = COUNT(CASE WHEN Sites.Quality = 0 THEN 1 ELSE NULL END),
           @UserSiteCount = COUNT(*),
           @YieldThreshold = MIN(Owners.TargetPouringYieldPercent)/100.0
    FROM Sites
    JOIN Owners ON Owners.ID = Sites.OwnerID
    WHERE Hidden = 0
END
ELSE
BEGIN
	SELECT @UserIDraughtSiteCount = COUNT(CASE WHEN Sites.Quality = 1 THEN 1 ELSE NULL END),
           @UserBMSSiteCount = COUNT(CASE WHEN Sites.Quality = 0 THEN 1 ELSE NULL END),
           @UserSiteCount = COUNT(*),
           @YieldThreshold = MIN(Owners.TargetPouringYieldPercent)/100.0
	FROM UserSites
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
    JOIN Owners ON Owners.ID = Sites.OwnerID
	WHERE UserID = @UserID
	AND Hidden = 0
END

IF @Anonymise = 1
BEGIN
	SET @UserName = 'Mr. Smith'
END

SELECT  @UserName AS UserName,
		@LastWebsiteLoginDate AS LastWebsiteLoginDate,
		@UserTypeID AS UserTypeID,
		CAST(1 AS BIT) AS EstateReporting,	-- deprecated June 2013
		1.0 AS CleaningThreshold,		-- deprecated June 2013
		ISNULL(@YieldThreshold, 0) AS YieldThreshold,
		@UserType AS UserType,
		@EMail AS EMail,
		@UserSiteCount AS UserSiteCount,
		@UserIDraughtSiteCount AS UserIDraughtSiteCount,
		@UserBMSSiteCount AS UserBMSSiteCount


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserDetailsAndUpdateLogin] TO PUBLIC
    AS [dbo];

