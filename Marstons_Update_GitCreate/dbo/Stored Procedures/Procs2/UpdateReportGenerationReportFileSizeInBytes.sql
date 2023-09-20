CREATE PROCEDURE UpdateReportGenerationReportFileSizeInBytes
(
	@ReportGenerationID		BIGINT,
	@ReportFileSizeInBytes		BIGINT
)
AS
EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateReportGenerationReportFileSizeInBytes @ReportGenerationID, @ReportFileSizeInBytes

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateReportGenerationReportFileSizeInBytes] TO PUBLIC
    AS [dbo];

