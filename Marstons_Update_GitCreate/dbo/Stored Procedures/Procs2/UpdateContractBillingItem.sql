CREATE PROCEDURE [dbo].[UpdateContractBillingItem]
(
	@ContractID				INT,
	@BillingItemID			INT,
	@IsCharged				BIT,
	@BMSRetailPrice			MONEY,
	@IDraughtRetailPrice	MONEY,
	@LabourTypeID			INT = NULL,
	@LabourMinutes			INT = NULL, 
	@LabourCharge			FLOAT = NULL,
	@PartsCharge			FLOAT = NULL
)
AS

SET NOCOUNT ON

DECLARE @OldIsCharged				BIT
DECLARE @OldBMSRetailPrice			MONEY
DECLARE @OldIDraughtRetailPrice	MONEY
DECLARE @OldLabourTypeID			INT
DECLARE @OldLabourMinutes			INT
DECLARE @OldLabourCharge			FLOAT
DECLARE @OldPartsCharge			FLOAT
DECLARE @BillingItemDescription		VARCHAR(100)
DECLARE @LabourTypeDescription		VARCHAR(100)
DECLARE @OldLabourTypeDescription		VARCHAR(100)
DECLARE @ChangeDescription			VARCHAR(8000)

SELECT 	@OldIsCharged = IsCharged,
		@OldBMSRetailPrice = BMSRetailPrice,
		@OldIDraughtRetailPrice = IDraughtRetailPrice,
		@OldLabourTypeID = LabourTypeID,
		@OldLabourMinutes = LabourMinutes,
		@OldLabourCharge = LabourCharge,
		@OldPartsCharge = PartsCharge
FROM dbo.ContractBillingItems
WHERE ContractID = @ContractID
AND BillingItemID = @BillingItemID

UPDATE dbo.ContractBillingItems
SET IsCharged = @IsCharged,
	BMSRetailPrice = @BMSRetailPrice,
	IDraughtRetailPrice = @IDraughtRetailPrice,
	LabourTypeID = @LabourTypeID,
	LabourMinutes = @LabourMinutes,
	LabourCharge = @LabourCharge,
	PartsCharge = @PartsCharge
WHERE ContractID = @ContractID
AND BillingItemID = @BillingItemID

SELECT @BillingItemDescription = [Description]
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
WHERE BillingItems.[ID] = @BillingItemID

IF ISNULL(@OldIsCharged, 0) <> ISNULL(@IsCharged, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'Is Charged changed from ' + CAST(ISNULL(@OldIsCharged, 0) AS VARCHAR) + ' to ' + CAST(@IsCharged AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldBMSRetailPrice, 0) <> ISNULL(@BMSRetailPrice, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'BMS Retail Price changed from ' + CAST(ISNULL(@OldBMSRetailPrice, 0) AS VARCHAR) + ' to ' + CAST(@BMSRetailPrice AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldIDraughtRetailPrice, 0) <> ISNULL(@IDraughtRetailPrice, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'IDraught Retail Price changed from ' + CAST(ISNULL(@OldIDraughtRetailPrice, 0) AS VARCHAR) + ' to ' + CAST(@IDraughtRetailPrice AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldLabourMinutes, 0) <> ISNULL(@LabourMinutes, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'Labour Minutes changed from ' + CAST(ISNULL(@OldLabourMinutes, 0) AS VARCHAR) + ' to ' + CAST(@LabourMinutes AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldLabourCharge, 0) <> ISNULL(@LabourCharge, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'Labour Charge changed from ' + CAST(ISNULL(@OldLabourCharge, 0) AS VARCHAR) + ' to ' + CAST(@LabourCharge AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldPartsCharge, 0) <> ISNULL(@PartsCharge, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'Parts Charge changed from ' + CAST(ISNULL(@OldPartsCharge, 0) AS VARCHAR) + ' to ' + CAST(@PartsCharge AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

IF ISNULL(@OldLabourTypeID, 0) <> ISNULL(@LabourTypeID, 0)
BEGIN
	SELECT @LabourTypeDescription = [Description]
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.LabourTypes AS LabourTypes
	WHERE LabourTypes.[ID] = ISNULL(@LabourTypeID, 0)

	SELECT @OldLabourTypeDescription = [Description]
	FROM [EDISSQL1\SQL1].ServiceLogger.dbo.LabourTypes AS LabourTypes
	WHERE LabourTypes.[ID] = ISNULL(@OldLabourTypeID, 0)
	
	SET @ChangeDescription = 'Item: ' + @BillingItemDescription + '. ' + 'Labour Type changed from ' + CAST(ISNULL(@OldLabourTypeDescription, 0) AS VARCHAR) + ' to ' + CAST(@LabourTypeDescription AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Contract Billing Item', @ContractID, @ChangeDescription
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateContractBillingItem] TO PUBLIC
    AS [dbo];

