CREATE PROCEDURE [dbo].[GetDownloadServiceDailyQueue]

AS

EXEC [EDISSQL1\SQL1].DownloadService.dbo.GetEDISDailyQueue
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDownloadServiceDailyQueue] TO PUBLIC
    AS [dbo];

