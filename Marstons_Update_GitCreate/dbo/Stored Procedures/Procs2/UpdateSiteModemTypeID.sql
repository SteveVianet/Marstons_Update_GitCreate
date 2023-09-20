---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateSiteModemTypeID
(
	@EDISID		INT,
	@ModemTypeID	INT,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS


IF 	(SELECT COUNT(*)
	FROM Sites 
	WHERE EDISID = @EDISID 
	AND UpdateID = @UpdateID) > 0 
     OR @UpdateID IS NULL
BEGIN
	UPDATE dbo.Sites
	SET ModemTypeID = @ModemTypeID
	WHERE EDISID = @EDISID

	SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

	RETURN 0

END
ELSE
BEGIN
	RETURN -1

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteModemTypeID] TO PUBLIC
    AS [dbo];

