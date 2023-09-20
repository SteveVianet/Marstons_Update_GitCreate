CREATE PROCEDURE [dbo].[InsertSite]
(	@OwnerID			INT,
    @SiteID				VARCHAR(15),
    @Name				VARCHAR(60),
    @TenantName			VARCHAR(50),
    @Address1			VARCHAR(50),
    @Address2			VARCHAR(50),
    @Address3			VARCHAR(50),
    @Address4			VARCHAR(50),
    @PostCode			VARCHAR(8),
    @SiteTelNo			VARCHAR(30),
    @EDISTelNo			VARCHAR(512),
    @EDISPassword		VARCHAR(15),
    @SiteOnline			DATETIME,
    @SerialNo			VARCHAR(255),
    @Region				INT,
    @Budget				FLOAT,
    @SiteClosed			BIT,
    @Classification		INT,
    @Version			VARCHAR(255),
    @LastDownload		SMALLDATETIME,
    @Comment			TEXT,
    @IsVRSMember		BIT,
    @ModemTypeID		INT,
    @BDMComment			TEXT,
    @SiteUser			VARCHAR(255),
    @InternalComment	TEXT,
    @SystemTypeID		INT,
    @AreaID				INT,
    @SiteGroupID		INT,
    @VRSOwner			INT,
    @CommunicationProviderID	INT,
    @OwnershipStatus	INT,
    @AltSiteTelNo		VARCHAR(30),
    @Quality			BIT,
    @InstallationDate	DATETIME,
    @GlobalEDISID		INT,
    @Hidden				BIT,
    @NewID				INT OUTPUT,
	@UpdateID			ROWVERSION = NULL	OUTPUT
)

AS

INSERT INTO Sites
	(OwnerID, SiteID, Name, TenantName, Address1, Address2, Address3, Address4, PostCode, SiteTelNo, EDISTelNo, EDISPassword, SiteOnline, SerialNo, Region, Budget, SiteClosed, Classification, Version, LastDownload, Comment, IsVRSMember, ModemTypeID, BDMComment, SiteUser, InternalComment, SystemTypeID, AreaID, SiteGroupID, VRSOwner, CommunicationProviderID, OwnershipStatus, AltSiteTelNo, Quality, InstallationDate, GlobalEDISID, Hidden)
VALUES
	(@OwnerID, @SiteID, @Name, @TenantName, @Address1, @Address2, @Address3, @Address4, @PostCode, @SiteTelNo, @EDISTelNo, @EDISPassword, @SiteOnline, @SerialNo, @Region, @Budget, @SiteClosed, @Classification, @Version, @LastDownload, @Comment, @IsVRSMember, @ModemTypeID, @BDMComment, @SiteUser, @InternalComment, @SystemTypeID, @AreaID, @SiteGroupID, @VRSOwner, @CommunicationProviderID, @OwnershipStatus, @AltSiteTelNo, @Quality, @InstallationDate, @GlobalEDISID, @Hidden)
	
SET @NewID = @@IDENTITY

SET @UpdateID =  @@DBTS

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertSite] TO PUBLIC
    AS [dbo];

