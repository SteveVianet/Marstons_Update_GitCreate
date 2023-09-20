CREATE PROCEDURE [dbo].[GetDownloadServiceHistory]
(
	@From		DATETIME,
	@To		DATETIME,
	@Interval	INT
)
AS

EXEC [EDISSQL1\SQL1].DownloadService.dbo.GetEDISHistory @From, @To, @Interval

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDownloadServiceHistory] TO PUBLIC
    AS [dbo];

