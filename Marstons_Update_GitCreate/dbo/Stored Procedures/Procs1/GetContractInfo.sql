CREATE PROCEDURE [dbo].[GetContractInfo]
(
	@ContractID INT
)

AS

SELECT [Description],
	ExpiryDate,
	DefaultRaiseStatus,
	RequiresPO,
	CanBeginWithoutPO,
	PercentageIncrease,
	StartDate,
	AllInclusive,
	NULL AS WarrantyCharge,
	NULL AS ServiceCharge,
	NULL AS TelecomsCharge,
	NULL AS DataCharge,
	[Owner],
	UseBillingItems,
	MaintenancePeriodMin,
	MaintenancePeriodMax,
	TermYears,
	LabourMinutesThreshold,
	InvoiceCostThreshold,
	DataWeeklyIncomePerSite,
	DataWeeklyIncome,
	ServiceWeeklyIncomePerSite,
	ServiceWeeklyIncome
FROM dbo.Contracts
WHERE [ID] = @ContractID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContractInfo] TO PUBLIC
    AS [dbo];

