CREATE PROCEDURE [dbo].[GetWebSiteSessionsOverview]
(
	@EDISID				INT,
	@IncludeInternal	BIT = 0,
	@RestrictToTenants	BIT = 0,
	@From				DATETIME = NULL,
	@To					DATETIME = NULL
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT

SELECT @DatabaseID = CAST(Configuration.PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

EXEC [SQL1\SQL1].ServiceLogger.[dbo].[GetWebSiteSessionsOverview] @DatabaseID, @EDISID, @IncludeInternal, @RestrictToTenants, @From, @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteSessionsOverview] TO PUBLIC
    AS [dbo];

