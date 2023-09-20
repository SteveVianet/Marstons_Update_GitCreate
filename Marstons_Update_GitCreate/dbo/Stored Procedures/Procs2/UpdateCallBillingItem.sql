CREATE PROCEDURE [dbo].[UpdateCallBillingItem]
(
	@CallID					INT,
	@BillingItemID			INT,
	@FullRetailPrice		FLOAT,
	@Quantity				INT,
	@LabourTypeID			INT = 0,
	@LabourMinutes			FLOAT = NULL
)
AS

SET NOCOUNT ON

DECLARE @ContractBillingItemID INT
DECLARE @ContractID INT
DECLARE @Quality BIT

IF @LabourMinutes IS NULL
BEGIN
	SELECT @ContractID = ContractID, @Quality = CASE WHEN Contracts.[Type] = 2 THEN 1 ELSE 0 END
	FROM Calls
	JOIN Contracts ON Contracts.ID = Calls.ContractID
	WHERE Calls.ID = @CallID

	SELECT @ContractBillingItemID = BillingItemID
	FROM ContractBillingItems
	WHERE ContractID = @ContractID
	AND BillingItemID = @BillingItemID

	IF @ContractBillingItemID IS NOT NULL
	BEGIN
		SELECT @LabourMinutes = CASE WHEN @Quality = 1 THEN COALESCE(CASE WHEN ContractBillingItems.LabourMinutes = 0 THEN NULL ELSE ContractBillingItems.LabourMinutes * @Quantity END, BillingItems.IDraughtLabourBy5Minutes * @Quantity) ELSE COALESCE(CASE WHEN ContractBillingItems.LabourMinutes = 0 THEN NULL ELSE ContractBillingItems.LabourMinutes * @Quantity END, BillingItems.BMSLabourBy5Minutes * @Quantity) END
		FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
		JOIN ContractBillingItems ON ContractBillingItems.BillingItemID = BillingItems.ID  
		WHERE ContractBillingItems.ContractID = @ContractID AND ContractBillingItems.BillingItemID = @BillingItemID
								
	END
	ELSE
	BEGIN
		SELECT @LabourMinutes = CASE WHEN @Quality = 1 THEN BillingItems.IDraughtLabourBy5Minutes * @Quantity ELSE BillingItems.BMSLabourBy5Minutes * @Quantity END
		FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
		WHERE BillingItems.[ID] = @BillingItemID

	END

	SET @LabourMinutes = ISNULL(@LabourMinutes, 0)
	
END

UPDATE dbo.CallBillingItems
SET FullRetailPrice = @FullRetailPrice,
	Quantity = @Quantity,
	LabourTypeID = @LabourTypeID,
	LabourMinutes = @LabourMinutes
WHERE CallID = @CallID
AND BillingItemID = @BillingItemID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallBillingItem] TO PUBLIC
    AS [dbo];

