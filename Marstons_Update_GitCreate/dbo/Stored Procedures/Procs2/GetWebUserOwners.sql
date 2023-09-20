CREATE PROCEDURE [dbo].[GetWebUserOwners]
(
	@UserID					INT = NULL,
	@EDISID					INT = NULL
)
AS

SET NOCOUNT ON

DECLARE @UserHasAllSites BIT
DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @UserHasAllSites = AllSitesVisible
FROM UserTypes
JOIN Users ON Users.UserType = UserTypes.ID
WHERE Users.ID = @UserID

SELECT	@DatabaseID AS DatabaseID,
		ID AS OwnerID,
		Name,
		TargetPouringYieldPercent,
		TargetTillYieldPercent,
		UseExceptionReporting,
		AllowSiteExceptionConfigurationOverride,
		ReportingFirstDayOfWeek
FROM Owners
WHERE ID IN
(
	SELECT DISTINCT OwnerID
	FROM Sites
	WHERE
	(
		((@UserHasAllSites = 1) OR 
		Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) AND @UserID IS NOT NULL)

		OR (@EDISID IS NOT NULL AND (Sites.EDISID = @EDISID OR @EDISID IS NULL))
	 
	)


)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserOwners] TO PUBLIC
    AS [dbo];

