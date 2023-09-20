CREATE PROCEDURE [dbo].[AddCallBillingItem]
(
	@CallID			INTEGER,
	@BillingItemID	INTEGER,
	@Quantity		FLOAT,
	@FullCostPrice	FLOAT = NULL OUTPUT,
	@FullRetailPrice FLOAT = NULL OUTPUT,
	@VATRate		FLOAT = NULL OUTPUT,
	@ContractID		INT = NULL OUTPUT,
	@LabourMinutes	FLOAT = NULL OUTPUT,
	@IsCharged		BIT = NULL OUTPUT,
	@LabourTypeID	INT = NULL OUTPUT
)
AS

SET NOCOUNT ON

DECLARE @Quality BIT
DECLARE @ContractBillingItemID INT
DECLARE @OriginalContractPrice FLOAT

SELECT @VATRate = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'VAT Rate'

SELECT @ContractID = Calls.ContractID, @Quality = CASE WHEN Contracts.[Type] = 2 THEN 1 ELSE 0 END
FROM Calls
JOIN Contracts ON Contracts.[ID] = Calls.ContractID
WHERE Calls.[ID] = @CallID

SELECT @IsCharged = IsCharged,
	   @ContractBillingItemID = BillingItemID
FROM ContractBillingItems
WHERE ContractID = @ContractID
AND BillingItemID = @BillingItemID

IF @ContractBillingItemID IS NOT NULL
BEGIN
	SELECT @FullRetailPrice = ContractBillingItems.PartsCharge,
		   @FullCostPrice = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtPartCost ELSE BillingItems.BMSPartCost END,
		   @LabourMinutes = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtLabourBy5Minutes * @Quantity ELSE BillingItems.BMSLabourBy5Minutes * @Quantity END,
		   @LabourTypeID = COALESCE(CASE WHEN ContractBillingItems.LabourTypeID = 0 THEN NULL ELSE ContractBillingItems.LabourTypeID END, BillingItems.LabourTypeID)
	FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
	JOIN ContractBillingItems ON ContractBillingItems.BillingItemID = BillingItems.ID  
	WHERE ContractBillingItems.ContractID = @ContractID AND ContractBillingItems.BillingItemID = @BillingItemID
							
END
ELSE
BEGIN
	SELECT @FullRetailPrice = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtRetailPrice ELSE BillingItems.BMSRetailPrice END,
		   @FullCostPrice = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtPartCost ELSE BillingItems.BMSPartCost END,
		   @LabourMinutes = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtLabourBy5Minutes * @Quantity ELSE BillingItems.BMSLabourBy5Minutes * @Quantity END,
		   @LabourTypeID = BillingItems.LabourTypeID
	FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
	WHERE BillingItems.[ID] = @BillingItemID

END

SET @FullCostPrice = ISNULL(@FullCostPrice, 0) * @Quantity
SET @FullRetailPrice = ISNULL(@FullRetailPrice, 0) * @Quantity
SET @VATRate = ISNULL(@VATRate, 0)
SET @ContractID = ISNULL(@ContractID, 0)
SET @LabourMinutes = ISNULL(@LabourMinutes, 0)
SET @IsCharged = ISNULL(@IsCharged, 1)
SET @LabourTypeID = ISNULL(@LabourTypeID, 0)
SET @OriginalContractPrice = @FullRetailPrice

INSERT INTO dbo.CallBillingItems
(CallID, BillingItemID, Quantity, FullCostPrice, FullRetailPrice, VAT, ContractID, LabourMinutes, IsCharged, LabourTypeID, ContractPrice)
VALUES
(@CallID, @BillingItemID, @Quantity, @FullCostPrice, @FullRetailPrice, @VATRate, @ContractID, @LabourMinutes, @IsCharged, @LabourTypeID, @OriginalContractPrice)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallBillingItem] TO PUBLIC
    AS [dbo];

