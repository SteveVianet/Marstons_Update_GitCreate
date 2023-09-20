CREATE PROCEDURE AddDownloadReport
(
	@EDISID		INTEGER,
	@DownloadedOn	DATETIME,
	@ReportText		VARCHAR(100),
	@IsError		BIT
)

AS

INSERT INTO DownloadReports
(EDISID, DownloadedOn, ReportText, IsError)
VALUES
(@EDISID, @DownloadedOn, @ReportText, @IsError)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDownloadReport] TO PUBLIC
    AS [dbo];

