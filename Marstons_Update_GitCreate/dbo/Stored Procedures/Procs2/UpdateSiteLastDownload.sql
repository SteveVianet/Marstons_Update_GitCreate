---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateSiteLastDownload
(
	@EDISID		INT,
	@LastDownload	SMALLDATETIME,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS

UPDATE dbo.Sites
SET LastDownload = @LastDownload
WHERE EDISID = @EDISID

SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastDownload] TO PUBLIC
    AS [dbo];

