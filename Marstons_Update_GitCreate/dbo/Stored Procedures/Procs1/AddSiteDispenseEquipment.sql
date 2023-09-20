CREATE PROCEDURE [dbo].[AddSiteDispenseEquipment]
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


	INSERT INTO dbo.Sites (SystemTypeID, SerialNo,Version,Quality,EDISTelNo)
	VALUES(	@EquipmentType,@SerialNo,@Version,@iDraughtEnabled,@EDISTelNo)

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
    ON OBJECT::[dbo].[AddSiteDispenseEquipment] TO PUBLIC
    AS [dbo];

