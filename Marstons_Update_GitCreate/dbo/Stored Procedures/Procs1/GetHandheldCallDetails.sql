CREATE PROCEDURE [dbo].[GetHandheldCallDetails]
(
	@CallID		INT
)
AS

SET NOCOUNT ON

DECLARE @DatabaseID INT
DECLARE @CustomerName VARCHAR(100)
DECLARE @DefaultAuditor VARCHAR(50)

SELECT @DatabaseID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CustomerName = PropertyValue
FROM Configuration
WHERE PropertyName = 'Company Name'

SELECT @DefaultAuditor = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'AuditorName'

SELECT @DatabaseID AS DatabaseID,
	   Calls.[ID] AS CallID,
	   @CustomerName AS Customer,
	   Sites.EDISID,
	   dbo.GetCallReference(@CallID) AS CallReference,
	   CASE WHEN CallTypeID = 1 THEN 'Service Call' ELSE 'Installation' END AS JobType,
	   CASE WHEN UseBillingItems = 1 THEN dbo.udfConcatCallReasonsSingleLine(@CallID) ELSE dbo.udfConcatCallFaultsSingleLine(@CallID) END AS Faults,
	   dbo.udfConcatSiteNotes(Sites.EDISID) AS Notes,
	   EngineerID,
	   SiteID,
	   Name,
	   CASE WHEN Address1 IS NULL THEN '' ELSE Address1 + ', ' END + 
	   CASE WHEN Address2 IS NULL THEN '' ELSE Address2 + ', ' END + 
	   CASE WHEN Address3 IS NULL THEN '' ELSE Address3 + ', ' END + 
	   CASE WHEN Address4 IS NULL THEN '' ELSE Address4 END AS FullAddress,
	   PostCode,
	   ISNULL(SiteTelNo, '') + ' / ' + ISNULL(AltSiteTelNo, '') AS SiteTelNo,
	   EDISTelNo,
	   TenantName,
	   SystemTypes.[Description] AS SystemType,
	   CASE WHEN SiteUser IS NULL THEN @DefaultAuditor ELSE dbo.udfNiceName(SiteUser) END AS Auditor,
	   CASE ProposedFontSetups.GlasswareStateID WHEN 0 THEN 'No'
												WHEN 1 THEN 'Yes'
												WHEN 2 THEN 'Partial'
												WHEN 3 THEN 'Key Products'
												ELSE 'No' END AS CalibrationStatus,
		ModemTypes.[Description] AS NetworkOperator,
		Calls.UseBillingItems
FROM Calls
JOIN Sites ON Sites.EDISID = Calls.EDISID
JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
JOIN ModemTypes ON ModemTypes.ID = Sites.ModemTypeID
LEFT JOIN (SELECT EDISID, MAX([ID]) AS [ID]
			FROM ProposedFontSetups
			WHERE Available = 1
			GROUP BY EDISID) AS LastAvailableFontSetup ON LastAvailableFontSetup.EDISID = Sites.EDISID
LEFT JOIN ProposedFontSetups ON ProposedFontSetups.[ID] = LastAvailableFontSetup.[ID]
WHERE Calls.[ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHandheldCallDetails] TO PUBLIC
    AS [dbo];

