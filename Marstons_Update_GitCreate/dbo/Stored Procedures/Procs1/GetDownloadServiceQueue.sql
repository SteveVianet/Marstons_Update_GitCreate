CREATE PROCEDURE [dbo].[GetDownloadServiceQueue]

AS

EXEC [EDISSQL1\SQL1].DownloadService.dbo.GetEDISQueue

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDownloadServiceQueue] TO PUBLIC
    AS [dbo];

