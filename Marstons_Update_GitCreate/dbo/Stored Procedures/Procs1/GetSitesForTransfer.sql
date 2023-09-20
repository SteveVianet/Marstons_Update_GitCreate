CREATE PROCEDURE [dbo].[GetSitesForTransfer]

AS

-- Get the site details.
SELECT	Sites.EDISID,
		OwnerID,
		SiteID,
		[Name] AS SiteName,
		TenantName,
		Address1, Address2, Address3, Address4, PostCode,
		SiteTelNo, EDISTelNo,
		EDISPassword,
		SiteOnline,
		Classification,
		SerialNo,
		Region, AreaID,
		Budget,
		SiteClosed,
		[Version],
		LastDownload,
		'' AS Comment,		-- To save time when connecting to database, these 3 fields have been disabled.
		'' AS BDMComment,	-- Their field contents, however, are still in the database itself.
		'' AS InternalComment,
		IsVRSMember,
		VRSOwner,
		ModemTypeID,
		SystemTypeID,
		Hidden,
		SiteUser,
		SiteGroupID,
		CommunicationProviderID,
		OwnershipStatus,
		AltSiteTelNo,
		UpdateID,
		Quality,
		InstallationDate,
		GlobalEDISID

FROM dbo.Sites 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesForTransfer] TO PUBLIC
    AS [dbo];

