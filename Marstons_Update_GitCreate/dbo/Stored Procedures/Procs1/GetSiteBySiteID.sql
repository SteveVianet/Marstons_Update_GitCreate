CREATE PROCEDURE [dbo].[GetSiteBySiteID]
(
	@SiteID VARCHAR(15)
)

AS

SELECT		OwnerID,
        EDISID,
		SiteID,
		[Name] AS SiteName,
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
		UpdateID
FROM dbo.Sites WITH (NOLOCK)
WHERE SiteID = @SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteBySiteID] TO PUBLIC
    AS [dbo];

