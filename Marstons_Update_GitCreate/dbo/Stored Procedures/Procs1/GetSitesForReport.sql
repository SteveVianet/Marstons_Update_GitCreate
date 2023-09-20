CREATE PROCEDURE [dbo].[GetSitesForReport]
(
	@ShowHidden			BIT = 0,
    @UserID             INT = NULL,
    @EDISID             INT = NULL
)

AS

--DECLARE    @ShowHidden		 BIT = 0
--DECLARE    @UserID             INT = NULL
--DECLARE    @EDISID             INT = NULL

SET NOCOUNT ON

DECLARE @UserHasAllSites BIT = 0

IF @UserID IS NOT NULL
BEGIN
    -- Which sites are we allowed to see?
    SELECT @UserHasAllSites = AllSitesVisible
    FROM dbo.UserTypes
    JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
    WHERE dbo.Users.[ID] = @UserID
END
ELSE
BEGIN
    SET @UserHasAllSites = 1
END

;WITH BDMUsers AS (
    -- Inefficient as it pulls all BDM users, not only relvant ones based on the current UserID
    SELECT 
        [ID],
        [UserName],
        [EDISID],
        ROW_NUMBER() OVER (PARTITION BY [EDISID] ORDER BY [UserName]) AS RowNum
    FROM [dbo].[Users]
    JOIN [dbo].[UserSites] ON [Users].[ID] = [UserSites].[UserID]
    WHERE [UserType] = 2 -- BDM
    AND (@EDISID IS NULL OR [EDISID] = @EDISID)
)
-- Get the site details.
SELECT	DISTINCT
        [Sites].[EDISID],
		[SiteID],
		[Name],
		COALESCE([Address3], [Address4]) AS [Town],
        [PostCode],
        [BDMUsers].[UserName] AS [BDM]
FROM [dbo].[Sites]
JOIN [dbo].[UserSites]
    ON [Sites].[EDISID] = [UserSites].[EDISID]
LEFT JOIN  [BDMUsers]
    ON [Sites].[EDISID] = [BDMUsers].[EDISID]
    AND [BDMUsers].[RowNum] = 1
WHERE 
    ([Hidden] = 0 OR @ShowHidden = 1)
AND [Status] IN (
    1,  -- Installed (Active)
    2,  -- Installed (Closed)
    3,  -- Installed (Legals)
    10  -- Free of Tie
    )
AND (@UserHasAllSites = 1 OR [UserSites].[UserID] = @UserID)
AND (@EDISID IS NULL OR [Sites].[EDISID] = @EDISID)
ORDER BY [EDISID], [Name]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesForReport] TO PUBLIC
    AS [dbo];

