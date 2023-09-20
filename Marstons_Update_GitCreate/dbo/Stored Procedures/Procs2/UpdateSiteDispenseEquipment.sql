CREATE PROCEDURE [dbo].[UpdateSiteDispenseEquipment]
(	@EDISID			INTEGER,
	@EquipmentType	INTEGER,
	@Version		VARCHAR(15),
	@iDraughtEnabled BIT,
	@EDISTelNo		VARCHAR(512),
	@SerialNo		VARCHAR(255),
	@UpdateID		ROWVERSION = NULL	OUTPUT
)

AS
SET XACT_ABORT ON

BEGIN TRAN

SET NOCOUNT ON


-- If edis tel no is not assigned already to another site it's ok
IF 	((SELECT COUNT(*)
	FROM dbo.Sites 
	WHERE EDISID <> @EDISID 
	AND EDISTelNo = @EDISTelNo) = 0 OR @EDISTelNo = '')

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
	SET	SystemTypeID = @EquipmentType,
		 SerialNo = @SerialNo,
		 Version = @Version,
		 Quality = @iDraughtEnabled,
		EDISTelNo = @EDISTelNo

	WHERE EDISID = @EDISID

	SET @UpdateID = (SELECT UpdateID FROM dbo.Sites WHERE EDISID = @EDISID)
	

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
    ON OBJECT::[dbo].[UpdateSiteDispenseEquipment] TO PUBLIC
    AS [dbo];

