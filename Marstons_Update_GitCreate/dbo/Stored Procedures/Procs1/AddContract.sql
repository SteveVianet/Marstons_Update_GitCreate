CREATE PROCEDURE [dbo].[AddContract]
(
	@Description		VARCHAR(255),
	@ExpiryDate			DATETIME,
	@DefaultRaiseStatus	INTEGER,
	@RequiresPO			BIT,
	@CanBeginWithoutPO	BIT,
	@PercentageIncrease	INTEGER,
	@StartDate			DATETIME,
	@AllInclusive		BIT,
	@Owner				VARCHAR(255) = NULL,
	@NewID				INTEGER OUTPUT,
	@UseBillingItems	BIT = 1,
	@MaintenancePeriodMin	INTEGER = 17,
	@MaintenancePeriodMax	INTEGER = 28,
	@TermYears				INTEGER = NULL,
	@LabourMinutesThreshold INTEGER = NULL,
	@InvoiceCostThreshold	FLOAT = NULL,
	@DataWeeklyIncomePerSite FLOAT = NULL,
	@DataWeeklyIncome		FLOAT = NULL,
	@ServiceWeeklyIncomePerSite	FLOAT = NULL,
	@ServiceWeeklyIncome		FLOAT = NULL,
	@Type					INT = NULL
)
AS

INSERT INTO dbo.Contracts
([Description], ExpiryDate, DefaultRaiseStatus, RequiresPO, CanBeginWithoutPO, PercentageIncrease, StartDate, AllInclusive, [Owner], UseBillingItems, MaintenancePeriodMin, MaintenancePeriodMax, [Type])
VALUES
(@Description, @ExpiryDate, @DefaultRaiseStatus, @RequiresPO, @CanBeginWithoutPO, @PercentageIncrease, @StartDate, @AllInclusive, @Owner, 1, @MaintenancePeriodMin, @MaintenancePeriodMax, @Type)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContract] TO PUBLIC
    AS [dbo];

