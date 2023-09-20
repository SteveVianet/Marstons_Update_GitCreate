CREATE PROCEDURE [dbo].[UpdateSiteSerialNo]
(	@EDISID			INTEGER,
	@EDISTelNo		VARCHAR(512),
	@SerialNo		VARCHAR(255)
)

AS
SET XACT_ABORT ON

BEGIN TRAN

SET NOCOUNT ON

-- If EDISID exists and UpdateID matches
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
	SET	
		EDISTelNo = @EDISTelNo, 
		SerialNo = @SerialNo,
		ModemTypeID = @ModemTypeID
	WHERE EDISID = @EDISID

    /* Update AuditSites */
    DECLARE @DatabaseID INT

    SELECT @DatabaseID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'

    EXEC [EDISSQL1\SQL1].[Auditing].dbo.UpdateSiteSerialNo @DatabaseID, @EDISID, @SerialNo
    /* -END- */

	COMMIT
	RETURN 0