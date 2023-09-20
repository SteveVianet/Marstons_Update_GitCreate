CREATE PROCEDURE GetDownloadReports
(
	@EDISID	INTEGER = NULL,
	@DateFrom	DATETIME = NULL,
	@DateTo	DATETIME = NULL,
	@OnlyErrors	BIT = 0
)

AS

SELECT EDISID,
		DownloadedOn,
		ReportText,
		IsError
FROM DownloadReports
WHERE (@EDISID IS NULL OR EDISID = @EDISID) AND
((@DateFrom IS NULL AND @DateTo IS NULL)
OR
(@DateFrom IS NULL AND DownloadedOn <= @DateTo)
OR
(@DateTo IS NULL AND DownloadedOn >= @DateFrom)
OR
(DownloadedOn BETWEEN @DateFrom AND @DateTo)) AND
(@OnlyErrors = 0 OR IsError = 1)
ORDER BY ID DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDownloadReports] TO PUBLIC
    AS [dbo];

