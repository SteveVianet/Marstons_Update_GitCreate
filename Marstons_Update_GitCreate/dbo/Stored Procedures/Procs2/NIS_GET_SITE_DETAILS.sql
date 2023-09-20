CREATE PROCEDURE dbo.NIS_GET_SITE_DETAILS
(
	@EDISID	AS	INT
)
AS
DECLARE @GateWayID AS VARCHAR(255)
SET @GateWayID = 	(SELECT Value 
			FROM SiteProperties
				JOIN Properties ON Properties.ID = SiteProperties.PropertyID
			WHERE (Properties.Name = 'GatewayID') AND (EDISID = @EDISID))
SELECT     EDISID, ISNULL(@GateWayID, '') AS GateWayID, '' AS GateWayNumber, '' AS ServerName, '' AS DatabaseName, '' AS MIDASType,
		0 AS SiteStatus, '' AS ServiceJobDescription, Name AS SiteName, PostCode, Address4 AS County, Address2 AS Town
FROM         dbo.Sites
WHERE     (EDISID = @EDISID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[NIS_GET_SITE_DETAILS] TO PUBLIC
    AS [dbo];

