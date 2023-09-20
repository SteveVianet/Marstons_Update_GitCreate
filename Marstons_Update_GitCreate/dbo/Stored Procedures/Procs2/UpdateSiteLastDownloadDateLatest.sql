CREATE PROCEDURE [dbo].[UpdateSiteLastDownloadDateLatest]
(
	@EDISID		INT,
	@LastDownload	SMALLDATETIME,
	@UpdateID	ROWVERSION = NULL	OUTPUT
)

AS

UPDATE dbo.Sites
SET LastDownload = @LastDownload
WHERE EDISID = @EDISID
AND (LastDownload < @LastDownload OR LastDownload IS NULL)
SET @UpdateID = (SELECT UpdateID FROM Sites WHERE EDISID = @EDISID)
