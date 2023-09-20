---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[UpdateAdditionalSiteDetails]
(
	@EDISID					INTEGER,
	@Quality				BIT,
	@SystemTypeID			INT,
	@CommunicationProvider	INT,
	@LastDownload			SMALLDATETIME,
	@IsVRSMember			BIT,
	@VRSOwner				INT,
	@OwnershipStatus		INT,
	@GlobalEDISID			INTEGER = NULL,
	@Version				VARCHAR(255) = NULL,
	@AltSiteTelNo			VARCHAR(50) = NULL,
	@InstallationDate		DATETIME = NULL
	
)

AS

UPDATE dbo.[Sites]
SET	[Version] = @Version,
	[LastDownload] = @LastDownload,
	[IsVRSMember] = @IsVRSMember,
	[SystemTypeID] = @SystemTypeID,
	[VRSOwner] = @VRSOwner,
	[CommunicationProviderID] = @CommunicationProvider,
	[OwnershipStatus] = @OwnershipStatus,
	[AltSiteTelNo] = @AltSiteTelNo,
	[Quality] = @Quality,
	[InstallationDate] = @InstallationDate,
	[GlobalEDISID] = @GlobalEDISID
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateAdditionalSiteDetails] TO PUBLIC
    AS [dbo];

