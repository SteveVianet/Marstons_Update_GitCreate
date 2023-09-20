CREATE PROCEDURE [neo].[GetSingleSite]
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
		o.Name AS Owner,
		SiteID,
		s.[Name] AS SiteName,
		@EDISID as EDISID,
		TenantName,
		s.Address1, s.Address2, s.Address3, s.Address4, PostCode,		
		sa.LastAudit,
		SiteTelNo, EDISTelNo,
		AltSiteTelNo,
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
		CASE UPPER(SpecialMeasures.Value)
			WHEN 'TRUE'	THEN 1
			WHEN 'YES'	THEN 1
			WHEN '1'	THEN 1
			ELSE 0
		END AS HasSpecialMeasures,
		SystemTypeID,
		Hidden,
		Quality,
		CAST(CASE UPPER(SiteUser) 
			WHEN UPPER(SUSER_SNAME()) THEN 1
			ELSE 0
			END AS BIT) AS OwnedSite,
		SiteUser AS SiteOwner,
		CommunicationProviderID,
		cp.ProviderName AS CommunicationProvider,
		OwnershipStatus,
		[Status],
		UpdateID,
		@BDM AS BDM,
		CASE WHEN InstallationDate IS NULL THEN CAST('2000-01-01' AS DATETIME)
		 ELSE InstallationDate
		END AS InstallationDate,
		LastMaintenanceDate,
		LastDownload
FROM dbo.Sites s WITH (NOLOCK)
LEFT JOIN Owners as o on o.ID = s.OwnerID
LEFT JOIN CommunicationProviders As cp
	ON cp.ID = s.CommunicationProviderID
LEFT JOIN (
		SELECT EDISID, Value
		FROM SiteProperties
		JOIN Properties 
			ON Properties.ID = SiteProperties.PropertyID
			AND UPPER(Properties.Name) = 'SPECIALMEASURES'
		) AS SpecialMeasures
		ON SpecialMeasures.EDISID = s.EDISID
LEFT JOIN (
	SELECT EDISID, MAX(TimeStamp) AS LastAudit
	FROM SiteAudits
	GROUP BY EDISID
	) AS sa ON  sa.EDISID = s.EDISID
WHERE s.EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetSingleSite] TO PUBLIC
    AS [dbo];

