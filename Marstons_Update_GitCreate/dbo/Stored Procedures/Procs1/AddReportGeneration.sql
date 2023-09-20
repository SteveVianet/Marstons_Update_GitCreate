CREATE PROCEDURE AddReportGeneration
(
	@EDISDatabaseID		INT,
	@ReportName		NVARCHAR(255),
	@UserName		NVARCHAR(255),
	@ComputerName		NVARCHAR(255),
	@MSExcelVersion		NVARCHAR(255),
	@SiteLibVersion		NVARCHAR(255),
	@MacroWFFNamePath	NVARCHAR(255),
	@AutoSend		BIT,
	@Started		DATETIME,
	@Finished		DATETIME,
	@LastProgress		DATETIME
)
AS
DECLARE @ReportGenerationID	AS	BIGINT
EXEC [SQL1\SQL1].ServiceLogger.dbo.AddReportGeneration @EDISDatabaseID, @ReportName, @UserName,@ComputerName, @MSExcelVersion, @SiteLibVersion, @MacroWFFNamePath, @AutoSend, @Started, @Finished, @LastProgress, @ReportGenerationID OUTPUT
RETURN @ReportGenerationID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddReportGeneration] TO PUBLIC
    AS [dbo];

