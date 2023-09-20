CREATE PROCEDURE [dbo].[GetDownloadServiceDailyQueueForDatabase]
(
	@DatabaseID	AS	int
)

AS

EXEC [EDISSQL1\SQL1].DownloadService.dbo.GetEDISDailyQueueForDatabase @DatabaseID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDownloadServiceDailyQueueForDatabase] TO PUBLIC
    AS [dbo];

