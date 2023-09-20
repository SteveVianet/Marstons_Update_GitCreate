
CREATE PROCEDURE [dbo].[AddOwner]
(
	@Name VARCHAR(255),
	@Address1 VARCHAR(255),
	@Address2 VARCHAR(255),
	@Address3 VARCHAR(255),
	@Address4 VARCHAR(255),
	@Postcode VARCHAR(9),
	@ContactName VARCHAR(255),
	@SendScorecardEmail BIT = 0,
	@POSYieldCashValue MONEY = 0,
	@CleaningCashValue MONEY = 0,
	@PouringYieldCashValue MONEY = 0,
	@TargetPouringYieldPercent INT = 0,
	@TargetTillYieldPercent INT = 0,
	@NewID INTEGER OUTPUT,
	@ScorecardFromEmailAddress VARCHAR(100) = NULL,
	@UseExceptionReporting BIT = 0,
	@AutoSendExceptions BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @DefaultOwnerID INT

-- Dirty way of not having 0% for the scorecard
IF @TargetPouringYieldPercent = 0
BEGIN
	SET @TargetPouringYieldPercent = 100
	
END

IF @TargetTillYieldPercent = 0
BEGIN
	SET @TargetTillYieldPercent = 100
	
END

INSERT INTO dbo.Owners
([Name], Address1, Address2, Address3, Address4, Postcode, ContactName, SendScorecardEmail, POSYieldCashValue, CleaningCashValue, PouringYieldCashValue, ScorecardFromEmailAddress, UseExceptionReporting, AutoSendExceptions)
VALUES
(@Name, @Address1, @Address2, @Address3, @Address4, @Postcode, @ContactName, @SendScorecardEmail, @POSYieldCashValue, @CleaningCashValue, @PouringYieldCashValue, @ScorecardFromEmailAddress, @UseExceptionReporting, @AutoSendExceptions)

SET @NewID = @@IDENTITY

INSERT INTO dbo.OwnerTradingShifts
(OwnerID, ShiftStartTime, ShiftDurationMinutes, [DayOfWeek], Name, TableNumber, TableColour)
VALUES
(@NewID, '05:00', 1440, 1, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 2, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 3, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 4, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 5, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 6, 'Default', 1, 'rgb(7, 145, 45)'),
(@NewID, '05:00', 1440, 7, 'Default', 1, 'rgb(7, 145, 45)')

SELECT @DefaultOwnerID = MIN(ID)
FROM Owners

IF @DefaultOwnerID <> @NewID AND @DefaultOwnerID IS NOT NULL
BEGIN
	UPDATE Owners
	SET Owners.ExceptionEmailHeaderHTML = DefaultOwner.ExceptionEmailHeaderHTML,
		Owners.ExceptionEmailFooterHTML  = DefaultOwner.ExceptionEmailFooterHTML,
		Owners.ExceptionEmailCleaningHTML = DefaultOwner.ExceptionEmailCleaningHTML,
		Owners.ExceptionEmailProductTempHTML = DefaultOwner.ExceptionEmailProductTempHTML,
		Owners.ExceptionEmailOverallYieldHTML = DefaultOwner.ExceptionEmailOverallYieldHTML,
		Owners.ExceptionEmailCellarTempHTML = DefaultOwner.ExceptionEmailCellarTempHTML,
		Owners.ExceptionEmailCoolerTempHTML = DefaultOwner.ExceptionEmailCoolerTempHTML,
		Owners.ExceptionEmailOutOfHoursDispenseHTML = DefaultOwner.ExceptionEmailOutOfHoursDispenseHTML,
		Owners.ExceptionEmailPouringYieldHTML = DefaultOwner.ExceptionEmailPouringYieldHTML,
		Owners.ExceptionEmailRetailYieldHTML = DefaultOwner.ExceptionEmailRetailYieldHTML,
		Owners.ExceptionEmailThroughputHTML = DefaultOwner.ExceptionEmailThroughputHTML,
		Owners.ExceptionEmailNoDataHTML = DefaultOwner.ExceptionEmailNoDataHTML,
		Owners.DailyScorecardHTML = DefaultOwner.DailyScorecardHTML,
		Owners.WeeklySiteReportHTML = DefaultOwner.WeeklySiteReportHTML,
		Owners.WeeklyExecReportHTML = DefaultOwner.WeeklyExecReportHTML,
		Owners.WelcomeEmailHTML = DefaultOwner.WelcomeEmailHTML,
		Owners.ExceptionEmailSubject = DefaultOwner.ExceptionEmailSubject,
		Owners.CellarAlarmEmailSubject = DefaultOwner.CellarAlarmEmailSubject,
		Owners.CoolerAlarmEmailSubject = DefaultOwner.CoolerAlarmEmailSubject,
		Owners.NoDataAlarmEmailSubject = DefaultOwner.NoDataAlarmEmailSubject,
		Owners.WeeklySiteReportSubject = DefaultOwner.WeeklySiteReportSubject,
		Owners.WeeklyExecReportSubject = DefaultOwner.WeeklyExecReportSubject,
		Owners.DailyScorecardSubject = DefaultOwner.DailyScorecardSubject,
		Owners.WelcomeEmailSubject = DefaultOwner.WelcomeEmailSubject
	FROM
	(
		SELECT	ExceptionEmailHeaderHTML,
				ExceptionEmailFooterHTML,
				ExceptionEmailCleaningHTML,
				ExceptionEmailProductTempHTML,
				ExceptionEmailOverallYieldHTML,
				ExceptionEmailCellarTempHTML,
				ExceptionEmailCoolerTempHTML,
				ExceptionEmailOutOfHoursDispenseHTML,
				ExceptionEmailPouringYieldHTML,
				ExceptionEmailRetailYieldHTML,
				ExceptionEmailThroughputHTML,
				ExceptionEmailNoDataHTML,
				DailyScorecardHTML,
				WeeklySiteReportHTML,
				WeeklyExecReportHTML,
				WelcomeEmailHTML,
				ExceptionEmailSubject,
				CellarAlarmEmailSubject,
				CoolerAlarmEmailSubject,
				NoDataAlarmEmailSubject,
				WeeklySiteReportSubject,
				WeeklyExecReportSubject,
				DailyScorecardSubject,
				WelcomeEmailSubject
		FROM Owners
		WHERE ID = @DefaultOwnerID
	) AS DefaultOwner
	WHERE ID = @NewID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddOwner] TO PUBLIC
    AS [dbo];

