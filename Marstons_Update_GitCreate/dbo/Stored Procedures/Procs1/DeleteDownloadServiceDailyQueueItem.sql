CREATE PROCEDURE [dbo].[DeleteDownloadServiceDailyQueueItem]
(
	@ID	AS	int
)


AS

EXEC [EDISSQL1\SQL1].DownloadService.dbo.DeleteEDISDailyQueueItem @ID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDownloadServiceDailyQueueItem] TO PUBLIC
    AS [dbo];

