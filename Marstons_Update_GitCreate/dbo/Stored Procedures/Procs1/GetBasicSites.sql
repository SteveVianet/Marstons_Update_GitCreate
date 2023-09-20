---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetBasicSites
(
	@ShowHidden		BIT = 0,
	@RestrictSitesByUser	BIT = 0
)

AS

SELECT	EDISID,
		OwnerID,
		SiteID,
		[Name] AS SiteName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteTelNo, EDISTelNo,
		EDISPassword,
		SiteOnline,
		SerialNo,
		Region, AreaID,
		SiteClosed,
		LastDownload,
		IsVRSMember,
		ModemTypeID,
		SystemTypeID,
		Hidden
FROM dbo.Sites WITH (NOLOCK)
WHERE (Hidden = 0 OR @ShowHidden = 1)
AND (	UPPER(SiteUser) = UPPER(SUSER_SNAME()) 
	OR @RestrictSitesByUser = 0
	OR SiteUser = ''
	OR SiteUser IS NULL)
ORDER BY SiteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetBasicSites] TO PUBLIC
    AS [dbo];

