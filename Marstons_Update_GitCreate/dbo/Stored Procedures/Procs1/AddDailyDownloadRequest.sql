CREATE PROCEDURE [dbo].[AddDailyDownloadRequest]
(
	@Server	VARCHAR(255),
	@Database	VARCHAR(255),
	@EDISID	VARCHAR(255),
	@StartAt	DATETIME,
	@Priority	TINYINT,
	@SiteAdded	INT 		OUTPUT
)

AS

EXEC @SiteAdded = [EDISSQL1\SQL1].DownloadService.dbo.AddDailyDownloadRequest @Server, @Database, @EDISID, @StartAt, @Priority
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDailyDownloadRequest] TO PUBLIC
    AS [dbo];

