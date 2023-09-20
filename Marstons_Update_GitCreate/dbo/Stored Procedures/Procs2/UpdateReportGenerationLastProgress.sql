


CREATE PROCEDURE UpdateReportGenerationLastProgress
(
	@ReportGenerationID		BIGINT,
	@LastProgress			DATETIME
)
AS
EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateReportGenerationLastProgress @ReportGenerationID, @LastProgress

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateReportGenerationLastProgress] TO PUBLIC
    AS [dbo];

