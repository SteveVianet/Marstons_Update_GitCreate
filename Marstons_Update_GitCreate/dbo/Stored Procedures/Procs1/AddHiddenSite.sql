CREATE PROCEDURE [dbo].[AddHiddenSite]
(
	@OwnerID		INTEGER,
	@SiteID		VARCHAR(15),
	@Name			VARCHAR(60),
	@TennantName		VARCHAR(50),
	@Address1		VARCHAR(50),
	@Address2		VARCHAR(50),
	@Address3		VARCHAR(50),
	@Address4		VARCHAR(50),
	@PostCode		VARCHAR(8),
	@SiteTelNo		VARCHAR(30),
	@EDISTelNo		VARCHAR(25),
	@EDISPassword	VARCHAR(15),
	@SiteOnline		DATETIME,
	@SerialNo		VARCHAR(255),
	@Region		INTEGER,
	@Budget		FLOAT,
	@SiteClosed		BIT,
	@NewID		INT OUTPUT,
	@NewUpdateID		ROWVERSION OUTPUT
)

AS
-- Do not add site that already exists
IF EXISTS (SELECT EDISID FROM Sites WHERE SiteID = @SiteID)
	RETURN 0

DECLARE @ModemTypeID INT = [dbo].GetModemTypeID(@EDISTelNo)

INSERT INTO dbo.Sites
(OwnerID, SiteID, [Name], TenantName, Address1, Address2, Address3, Address4,
PostCode, SiteTelNo, EDISTelNo, EDISPassword, SiteOnline, SerialNo,
Region, Budget, SiteClosed, Hidden, SiteUser, ModemTypeID)
VALUES
(@OwnerID, @SiteID, @Name, @TennantName,
@Address1, @Address2, @Address3, @Address4, @PostCode,
@SiteTelNo, @EDISTelNo, @EDISPassword,
@SiteOnline, @SerialNo, @Region, @Budget, @SiteClosed, 1, '', @ModemTypeID)

SET @NewID = @@IDENTITY
SET @NewUpdateID = @@DBTS

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddHiddenSite] TO [SiteCreator]
    AS [dbo];

