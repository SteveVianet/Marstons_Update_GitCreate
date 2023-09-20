CREATE PROCEDURE GetMostRecentDownloadReport
(
	@EDISID	INTEGER = NULL
)

AS

SELECT TOP 1
		EDISID,
		DownloadedOn,
		ReportText,
		IsError
FROM DownloadReports
WHERE EDISID = @EDISID
ORDER BY ID DESC


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMostRecentDownloadReport] TO PUBLIC
    AS [dbo];

