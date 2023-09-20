CREATE PROCEDURE [dbo].[UpdateSiteEDISTelNo]
(
	@EDISID		INT,
	@EDISTelNo		VARCHAR(50)
)

AS
DECLARE @ModemTypeID INT 
	
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

UPDATE Sites
SET	EDISTelNo = @EDISTelNo, 
	ModemTypeID = @ModemTypeID
WHERE [EDISID] = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteEDISTelNo] TO PUBLIC
    AS [dbo];

