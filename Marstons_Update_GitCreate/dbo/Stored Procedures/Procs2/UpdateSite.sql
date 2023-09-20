CREATE PROCEDURE [dbo].[UpdateSite]
(	@EDISID			INTEGER,
	@OwnerID		INTEGER,
	@SiteID			VARCHAR(15),
	@SiteName		VARCHAR(60),
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
	@UpdateID		ROWVERSION = NULL	OUTPUT
)

AS
SET XACT_ABORT ON

BEGIN TRAN

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalOwnerID	INTEGER

-- If EDISID exists and UpdateID matches
IF 	(SELECT COUNT(*)
	FROM dbo.Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN

	DECLARE @ModemTypeID INT = 8

	IF (SELECT EDISTelNo 
		FROM dbo.Sites 
		WHERE EDISID = @EDISID) <> @EDISTelNo
	BEGIN
		SET @ModemTypeID = [dbo].GetModemTypeID(@EDISTelNo)
	END
	ELSE
	BEGIN
		SET @ModemTypeID = (SELECT ModemTypeID 
			FROM dbo.Sites 
			WHERE EDISID = @EDISID)
	END

	UPDATE dbo.Sites
	SET	OwnerID = @OwnerID,
		SiteID = @SiteID, 
		[Name] = @SiteName, 
		TenantName = @TennantName, 
		Address1 = @Address1, 
		Address2 = @Address2, 
		Address3 = @Address3, 
		Address4 = @Address4,
		PostCode = @PostCode, 
		SiteTelNo = @SiteTelNo, 
		EDISTelNo = @EDISTelNo, 
		EDISPassword = @EDISPassword, 
		SiteOnline = @SiteOnline, 
		SerialNo = @SerialNo,
		Region = @Region, 
		Budget = @Budget,
		ModemTypeID = @ModemTypeID
		--SiteClosed = @SiteClosed
	WHERE EDISID = @EDISID

	SET @UpdateID = (SELECT UpdateID FROM dbo.Sites WHERE EDISID = @EDISID)
	
	/*
	SELECT @GlobalEDISID = GlobalEDISID
	FROM Sites
	WHERE EDISID = @EDISID

	IF @GlobalEDISID IS NOT NULL
	BEGIN
		SELECT @GlobalOwnerID = GlobalOwners.[ID]
		FROM [SQL2\SQL2].[Global].dbo.Owners AS GlobalOwners
		JOIN Owners ON Owners.[Name] = GlobalOwners.[Name]
		JOIN Sites ON Sites.OwnerID = Owners.[ID]
		WHERE Sites.GlobalEDISID = @GlobalEDISID
		
		EXEC [SQL2\SQL2].[Global].dbo.UpdateSite @GlobalEDISID, @GlobalOwnerID, @SiteID, @SiteName, @TennantName, @Address1, @Address2, @Address3, @Address4, @PostCode, @SiteTelNo, @EDISTelNo, @EDISPassword, @SiteOnline, @SerialNo, 1, @Budget, @SiteClosed, NULL
	
	END
	*/

    /* Update AuditSites */
    DECLARE @DatabaseID INT

    SELECT @DatabaseID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

    EXEC [SQL1\SQL1].[Auditing].dbo.UpdateSiteSerialNo @DatabaseID, @EDISID, @SerialNo
    /* -END- */

	COMMIT
	RETURN 0

END
ELSE
BEGIN
	COMMIT
	RETURN -1

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSite] TO PUBLIC
    AS [dbo];

