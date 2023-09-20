---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateSiteVersion
(
	@EDISID		INT,
	@Version	VARCHAR(255),
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
	SET Version = @Version
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
    ON OBJECT::[dbo].[UpdateSiteVersion] TO PUBLIC
    AS [dbo];

