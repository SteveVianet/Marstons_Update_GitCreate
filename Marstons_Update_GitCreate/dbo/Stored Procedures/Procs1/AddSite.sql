
CREATE PROCEDURE [dbo].[AddSite]
(
	@OwnerID		INTEGER,
	@SiteID			VARCHAR(15),
	@Name			VARCHAR(60),
	@TennantName	VARCHAR(50),
	@Address1		VARCHAR(50),
	@Address2		VARCHAR(50),
	@Address3		VARCHAR(50),
	@Address4		VARCHAR(50),
	@PostCode		VARCHAR(8),
	@SiteTelNo		VARCHAR(30),
	@EDISTelNo		VARCHAR(512),
	@EDISPassword	VARCHAR(15),
	@SiteOnline		DATETIME,
	@SerialNo		VARCHAR(255),
	@Region			INTEGER,
	@Budget			FLOAT,
	@SiteClosed		BIT,
	@NewID			INT		OUTPUT,
	@NewUpdateID	ROWVERSION	OUTPUT,
	@Hidden			BIT = 0
)

AS

SET NOCOUNT ON

-- get network based on @EDISTelNo
DECLARE @ModemTypeID INT = [dbo].GetModemTypeID(@EDISTelNo)

-- If we are adding a site as hidden, then we do not wish to set the SiteUser property
IF @Hidden = 0
BEGIN
	INSERT INTO dbo.Sites
	(OwnerID, SiteID, [Name], TenantName, Address1, Address2, Address3, Address4, PostCode, SiteTelNo, EDISTelNo, EDISPassword, SiteOnline, SerialNo, Region, Budget, SiteClosed, ModemTypeID)
	VALUES
	(@OwnerID, @SiteID, @Name, @TennantName, @Address1, @Address2, @Address3, @Address4, @PostCode, @SiteTelNo, @EDISTelNo, @EDISPassword, @SiteOnline, @SerialNo, @Region, @Budget, @SiteClosed, @ModemTypeID)
	
	SET @NewID = @@IDENTITY
	SET @NewUpdateID = @@DBTS
END
ELSE
BEGIN
	INSERT INTO dbo.Sites
	(OwnerID, SiteID, [Name], TenantName, Address1, Address2, Address3, Address4, PostCode, SiteTelNo, EDISTelNo, EDISPassword, SiteOnline, SerialNo, Region, Budget, SiteClosed, Hidden, SiteUser, ModemTypeID)
	VALUES
	(@OwnerID, @SiteID, @Name, @TennantName, @Address1, @Address2, @Address3, @Address4, @PostCode, @SiteTelNo, @EDISTelNo, @EDISPassword, @SiteOnline, @SerialNo, @Region, @Budget, @SiteClosed, @Hidden, '', @ModemTypeID)
	
	SET @NewID = @@IDENTITY
	SET @NewUpdateID = @@DBTS
END

INSERT INTO dbo.SiteTradingShifts
(EDISID, ShiftStartTime, ShiftDurationMinutes, [DayOfWeek], Name)
SELECT @NewID AS EDISID, ShiftStartTime, ShiftDurationMinutes, [DayOfWeek], Name
FROM OwnerTradingShifts
WHERE OwnerID = @OwnerID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSite] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSite] TO [SiteCreator]
    AS [dbo];

