CREATE PROCEDURE [dbo].[GetSingleSite]
(
	@EDISID	INTEGER
)

AS

DECLARE @BDM varchar(255)

SELECT	TOP 1 @BDM = UserName
FROM	dbo.UserSites us
INNER JOIN	dbo.Users bdm ON us.UserID = bdm.ID AND bdm.UserType = 2
WHERE	us.EDISID = @EDISID

SELECT	OwnerID,
		SiteID,
		[Name] AS SiteName,
		@EDISID as EDISID,
		TenantName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteTelNo, EDISTelNo,
		EDISPassword,
		SiteOnline,
		SerialNo,
		Region, AreaID,
		Budget,
		SiteClosed,
		Version,
		LastDownload,
		'' AS Comment,		-- To save time when connecting to database, these 2 fields have been
		'' AS BDMComment,	-- disabled. The contents are, however, still in the database
		'' AS InternalComment,	-- Same with InternalComment
		IsVRSMember,
		ModemTypeID,
		SystemTypeID,
		Hidden,
		Quality,
		CAST(CASE UPPER(SiteUser) 
			WHEN UPPER(SUSER_SNAME()) THEN 1
			ELSE 0
			END AS BIT) AS OwnedSite,
		SiteUser AS SiteOwner,
		CommunicationProviderID,
		OwnershipStatus,
		AltSiteTelNo,
		[Status],
		UpdateID,
		@BDM AS BDM,
		CASE WHEN InstallationDate IS NULL THEN CAST('2000-01-01' AS DATETIME)
		 ELSE InstallationDate
		END AS InstallationDate,
		LastMaintenanceDate
FROM dbo.Sites s WITH (NOLOCK)
WHERE s.EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSingleSite] TO PUBLIC
    AS [dbo];

