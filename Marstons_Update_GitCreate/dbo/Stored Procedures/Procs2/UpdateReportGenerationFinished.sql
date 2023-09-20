


CREATE PROCEDURE UpdateReportGenerationFinished
(
	@ReportGenerationID		BIGINT,
	@Finished			DATETIME
)
AS
EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateReportGenerationFinished @ReportGenerationID, @Finished

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateReportGenerationFinished] TO PUBLIC
    AS [dbo];

