
CREATE PROCEDURE GetOwnerExceptionEmails
	@OwnerID INT
AS

SET NOCOUNT ON;

SELECT ExceptionEmailHeaderHTML AS 'Header',
	ExceptionEmailFooterHTML AS 'Footer',
	ExceptionEmailCleaningHTML AS 'Line Cleaning',
	ExceptionEmailProductTempHTML AS 'Product Temperature',
	ExceptionEmailOverallYieldHTML AS 'Overall Yield',
	ExceptionEmailCellarTempHTML AS 'Cellar Temperature',
	ExceptionEmailCoolerTempHTML AS 'Cooler Temperature',
	ExceptionEmailOutOfHoursDispenseHTML AS 'Out of Hours Dispense',
	ExceptionEmailPouringYieldHTML AS 'Pouring Yield',
	ExceptionEmailRetailYieldHTML AS 'Retail Yield',
	ExceptionEmailThroughputHTML AS 'Throughput',
	ExceptionEmailNoDataHTML AS 'No Data',
	DailyScorecardHTML AS 'Daily Scorecard',
	WeeklySiteReportHTML AS 'Weekly Site Report',
	WeeklyExecReportHTML AS 'Weekly Exec Report',
	WelcomeEmailHTML AS 'Welcome Email',
	ExceptionEmailSubject,
	CellarAlarmEmailSubject,
	CoolerAlarmEmailSubject,
	NoDataAlarmEmailSubject,
	WeeklySiteReportSubject,
	WeeklyExecReportSubject,
	DailyScorecardSubject,
	WelcomeEmailSubject,
	DispenseMonitoringDataHTML AS 'Dispense Monitoring Data',
	DispenseMonitoringDataSubject,
	PDFReportPackHTML AS 'PDF Report Pack',
	PDFReportPackSubject
FROM Owners
WHERE ID = @OwnerID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOwnerExceptionEmails] TO PUBLIC
    AS [dbo];

