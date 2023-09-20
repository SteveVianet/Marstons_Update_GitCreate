---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetAdditionalSiteDetails]
(
	@EDISID					INTEGER
)

AS

SELECT	[Version], [LastDownload], [IsVRSMember], [SystemTypeID], [VRSOwner], [CommunicationProviderID],
		[OwnershipStatus], [AltSiteTelNo], [Quality], [InstallationDate], [GlobalEDISID]
FROM	
	dbo.[Sites]
WHERE	
	EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAdditionalSiteDetails] TO PUBLIC
    AS [dbo];

