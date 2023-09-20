CREATE PROCEDURE [dbo].[UpdateContract]
(
	@ContractID				INT,
	@Description			VARCHAR(255),
	@ExpiryDate				DATETIME,
	@DefaultRaiseStatus		INT = 1,
	@RequiresPO				BIT,
	@CanBeginWithoutPO		BIT,
	@PercentageIncrease		INT,
	@StartDate				DATETIME,
	@AllInclusive			BIT,
	@Owner					VARCHAR(255),
	@UseBillingItems		BIT = 1,
	@MaintenancePeriodMin	INT = 17,
    @MaintenancePeriodMax	INT = 28,
    @TermYears				INT = NULL,
	@LabourMinutesThreshold	INT = NULL,
	@InvoiceCostThreshold	FLOAT = NULL,
	@DataWeeklyIncomePerSite	FLOAT = NULL,
	@DataWeeklyIncome		FLOAT = NULL,
	@ServiceWeeklyIncomePerSite	FLOAT = NULL,
	@ServiceWeeklyIncome	FLOAT = NULL,
	@Type					INT = NULL
)
AS

SET NOCOUNT ON

DECLARE	@OldDescription			VARCHAR(255)
DECLARE	@OldExpiryDate				DATETIME
DECLARE	@OldDefaultRaiseStatus		INT
DECLARE	@OldRequiresPO				BIT
DECLARE	@OldCanBeginWithoutPO		BIT
DECLARE	@OldPercentageIncrease		INT
DECLARE	@OldStartDate				DATETIME
DECLARE	@OldAllInclusive			BIT
DECLARE	@OldOwner					VARCHAR(255)
DECLARE	@OldUseBillingItems		BIT
DECLARE	@OldMaintenancePeriodMin	INT
DECLARE @OldMaintenancePeriodMax	INT
DECLARE @OldTermYears				INT
DECLARE	@OldLabourMinutesThreshold	INT
DECLARE	@OldInvoiceCostThreshold	FLOAT
DECLARE	@OldDataWeeklyIncomePerSite FLOAT
DECLARE	@OldDataWeeklyIncome		FLOAT
DECLARE	@OldServiceWeeklyIncomePerSite	FLOAT
DECLARE	@OldServiceWeeklyIncome	FLOAT
DECLARE	@OldType					INT
DECLARE @ChangeDescription			VARCHAR(8000)

SELECT	@OldDescription = [Description],
    @OldExpiryDate = ExpiryDate,
    @OldDefaultRaiseStatus = DefaultRaiseStatus,
    @OldRequiresPO = RequiresPO,
    @OldCanBeginWithoutPO = CanBeginWithoutPO,
    @OldPercentageIncrease = PercentageIncrease,
    @OldStartDate = StartDate,
    @OldAllInclusive = AllInclusive,
    @OldOwner = [Owner],
    @OldUseBillingItems = UseBillingItems,
    @OldMaintenancePeriodMin = MaintenancePeriodMin,
    @OldMaintenancePeriodMax = MaintenancePeriodMax,
    @OldTermYears = TermYears,
	@OldLabourMinutesThreshold = LabourMinutesThreshold,
	@OldInvoiceCostThreshold = InvoiceCostThreshold,
	@OldDataWeeklyIncomePerSite = DataWeeklyIncomePerSite,
	@OldDataWeeklyIncome = DataWeeklyIncome,
	@OldServiceWeeklyIncomePerSite = ServiceWeeklyIncomePerSite,
	@OldServiceWeeklyIncome = ServiceWeeklyIncome,
	@OldType = [Type]
FROM dbo.Contracts
WHERE [ID] = @ContractID

UPDATE dbo.Contracts
SET 
	[Description] = @Description,
    ExpiryDate = @ExpiryDate,
    DefaultRaiseStatus = CASE WHEN @DefaultRaiseStatus = 0 THEN 1 ELSE @DefaultRaiseStatus END,
    RequiresPO = @RequiresPO,
    CanBeginWithoutPO = @CanBeginWithoutPO,
    PercentageIncrease = @PercentageIncrease,
    StartDate = @StartDate,
    AllInclusive = @AllInclusive,
    [Owner] = @Owner,
    UseBillingItems = 1,
    MaintenancePeriodMin = @MaintenancePeriodMin,
    MaintenancePeriodMax = @MaintenancePeriodMax,
    TermYears = @TermYears,
	LabourMinutesThreshold = @LabourMinutesThreshold,
	InvoiceCostThreshold = @InvoiceCostThreshold,
	DataWeeklyIncomePerSite = @DataWeeklyIncomePerSite,
	DataWeeklyIncome = @DataWeeklyIncome,
	ServiceWeeklyIncomePerSite = @ServiceWeeklyIncomePerSite,
	ServiceWeeklyIncome = @ServiceWeeklyIncome,
	[Type] = @Type
WHERE [ID] = @ContractID

IF ISNULL(@OldDescription, '') <> ISNULL(@Description, '')
BEGIN
	SET @ChangeDescription = 'Description changed from ' + ISNULL(@OldDescription, '') + ' to ' + @Description
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldExpiryDate, 0) <> ISNULL(@ExpiryDate, 0)
BEGIN
	SET @ChangeDescription = 'Expiry Date changed from ' + CAST(ISNULL(@OldExpiryDate, 0) AS VARCHAR) + ' to ' + CAST(@ExpiryDate AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldDefaultRaiseStatus, 0) <> ISNULL(@DefaultRaiseStatus, 0)
BEGIN
	SET @ChangeDescription = 'Expiry Date changed from ' + CAST(ISNULL(@OldDefaultRaiseStatus, 0) AS VARCHAR) + ' to ' + CAST(@DefaultRaiseStatus AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldRequiresPO, 0) <> ISNULL(@RequiresPO, 0)
BEGIN
	SET @ChangeDescription = 'Requires PO changed from ' + CAST(ISNULL(@OldRequiresPO, 0) AS VARCHAR) + ' to ' + CAST(@RequiresPO AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldCanBeginWithoutPO, 0) <> ISNULL(@CanBeginWithoutPO, 0)
BEGIN
	SET @ChangeDescription = 'Can Begin Without PO changed from ' + CAST(ISNULL(@OldCanBeginWithoutPO, 0) AS VARCHAR) + ' to ' + CAST(@CanBeginWithoutPO AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldPercentageIncrease, 0) <> ISNULL(@PercentageIncrease, 0)
BEGIN
	SET @ChangeDescription = 'Percentage Increase changed from ' + CAST(ISNULL(@OldPercentageIncrease, 0) AS VARCHAR) + ' to ' + CAST(@PercentageIncrease AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldStartDate, 0) <> ISNULL(@StartDate, 0)
BEGIN
	SET @ChangeDescription = 'Start Date changed from ' + CAST(ISNULL(@OldStartDate, 0) AS VARCHAR) + ' to ' + CAST(@StartDate AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldAllInclusive, 0) <> ISNULL(@AllInclusive, 0)
BEGIN
	SET @ChangeDescription = 'All Inclusive changed from ' + CAST(ISNULL(@OldAllInclusive, 0) AS VARCHAR) + ' to ' + CAST(@AllInclusive AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldOwner, '') <> ISNULL(@Owner, '')
BEGIN
	SET @ChangeDescription = 'Owner changed from ' + CAST(ISNULL(@OldOwner, '') AS VARCHAR) + ' to ' + CAST(@Owner AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldUseBillingItems, 0) <> ISNULL(@UseBillingItems, 0)
BEGIN
	SET @ChangeDescription = 'Use Billing Items changed from ' + CAST(ISNULL(@OldUseBillingItems, 0) AS VARCHAR) + ' to ' + CAST(@UseBillingItems AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldMaintenancePeriodMin, 0) <> ISNULL(@MaintenancePeriodMin, 0)
BEGIN
	SET @ChangeDescription = 'Maintainance Period Min changed from ' + CAST(ISNULL(@OldMaintenancePeriodMin, 0) AS VARCHAR) + ' to ' + CAST(@MaintenancePeriodMin AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Maintenance', @ContractID, @ChangeDescription
END

IF ISNULL(@OldMaintenancePeriodMax, 0) <> ISNULL(@MaintenancePeriodMax, 0)
BEGIN
	SET @ChangeDescription = 'Maintainance Period Max changed from ' + CAST(ISNULL(@OldMaintenancePeriodMax, 0) AS VARCHAR) + ' to ' + CAST(@MaintenancePeriodMax AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Maintenance', @ContractID, @ChangeDescription
END

IF ISNULL(@OldTermYears, 0) <> ISNULL(@TermYears, 0)
BEGIN
	SET @ChangeDescription = 'Term Years changed from ' + CAST(ISNULL(@OldTermYears, 0) AS VARCHAR) + ' to ' + CAST(@TermYears AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldLabourMinutesThreshold, 0) <> ISNULL(@LabourMinutesThreshold, 0)
BEGIN
	SET @ChangeDescription = 'Labour Minutes Threshold changed from ' + CAST(ISNULL(@OldLabourMinutesThreshold, 0) AS VARCHAR) + ' to ' + CAST(@LabourMinutesThreshold AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldInvoiceCostThreshold, 0) <> ISNULL(@InvoiceCostThreshold, 0)
BEGIN
	SET @ChangeDescription = 'Invoice Cost Threshold changed from ' + CAST(ISNULL(@OldInvoiceCostThreshold, 0) AS VARCHAR) + ' to ' + CAST(@InvoiceCostThreshold AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldDataWeeklyIncomePerSite, 0) <> ISNULL(@DataWeeklyIncomePerSite, 0)
BEGIN
	SET @ChangeDescription = 'Data Weekly Income Per Site changed from ' + CAST(ISNULL(@OldDataWeeklyIncomePerSite, 0) AS VARCHAR) + ' to ' + CAST(@DataWeeklyIncomePerSite AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldDataWeeklyIncome, 0) <> ISNULL(@DataWeeklyIncome, 0)
BEGIN
	SET @ChangeDescription = 'Data Weekly Income changed from ' + CAST(ISNULL(@OldDataWeeklyIncome, 0) AS VARCHAR) + ' to ' + CAST(@DataWeeklyIncome AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldServiceWeeklyIncomePerSite, 0) <> ISNULL(@ServiceWeeklyIncomePerSite, 0)
BEGIN
	SET @ChangeDescription = 'Service Weekly Income Per Site changed from ' + CAST(ISNULL(@OldServiceWeeklyIncomePerSite, 0) AS VARCHAR) + ' to ' + CAST(@DataWeeklyIncome AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldServiceWeeklyIncome, 0) <> ISNULL(@ServiceWeeklyIncome, 0)
BEGIN
	SET @ChangeDescription = 'Service Weekly Income changed from ' + CAST(ISNULL(@OldServiceWeeklyIncome, 0) AS VARCHAR) + ' to ' + CAST(@ServiceWeeklyIncome AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

IF ISNULL(@OldType, 0) <> ISNULL(@Type, 0)
BEGIN
	SET @ChangeDescription = 'Type changed from ' + CAST(ISNULL(@OldType, 0) AS VARCHAR) + ' to ' + CAST(@Type AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract', @ContractID, @ChangeDescription
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateContract] TO PUBLIC
    AS [dbo];

