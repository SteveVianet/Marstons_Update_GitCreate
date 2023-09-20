CREATE PROCEDURE [dbo].[AddDownloadRequest]
(
	@Server	VARCHAR(255) = NULL,
	@Database	VARCHAR(255) = NULL,
	@EDISID	VARCHAR(255),
	@StartAt	DATETIME = NULL,
	@Priority	TINYINT = 1,
	@SiteAdded	INT		OUTPUT
)

AS

IF @Server IS NULL
BEGIN
	-- Look up Server and Database etc.
	SET @Server = @@SERVERNAME
	SET @Database = DB_NAME()
	SET @StartAt  = GETDATE()
	SET @Priority = 1
END

EXEC @SiteAdded = [EDISSQL1\SQL1].DownloadService.dbo.AddDownloadRequest @Server, @Database, @EDISID, @StartAt, @Priority

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDownloadRequest] TO PUBLIC
    AS [dbo];

