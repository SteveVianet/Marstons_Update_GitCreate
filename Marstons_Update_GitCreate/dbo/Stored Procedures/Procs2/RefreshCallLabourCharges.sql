CREATE PROCEDURE [dbo].[RefreshCallLabourCharges]
(
	@CallID		INT 
)
AS

SET NOCOUNT ON

DECLARE @ServiceCalloutChargeID		INT = 93
DECLARE @AdditionalLabour			INT = 92

DECLARE @ServiceCalloutCharge		FLOAT
DECLARE @AdditionalLabourCharge		FLOAT
DECLARE @AdditionalLabourQuantity	FLOAT
DECLARE @VisitStartedOn		DATETIME
DECLARE @VisitEndedOn		DATETIME
DECLARE @ContractID			INT
DECLARE @Quality			BIT
DECLARE @FixedItems			INT
DECLARE @VariableItems		INT
DECLARE @ChargedItems		INT
DECLARE @VariableLabourMinutes	FLOAT
DECLARE @LabourMinutes	FLOAT
DECLARE @AbortReasonID INT

SELECT @AbortReasonID = AbortReasonID
FROM Calls
WHERE ID = @CallID

IF @AbortReasonID > 0
BEGIN
	RETURN
END

SELECT	@FixedItems = SUM(CASE WHEN LabourTypeID = 1 THEN 1 ELSE 0 END),
		@VariableItems = SUM(CASE WHEN LabourTypeID = 2 THEN 1 ELSE 0 END),
		@ChargedItems = SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END)
FROM CallBillingItems
WHERE CallID = @CallID

SELECT	@VisitStartedOn = VisitStartedOn, 
		@VisitEndedOn = VisitedOn,
		@ContractID = ContractID,
		@Quality = QualitySite
FROM Calls
WHERE [ID] = @CallID

IF @ChargedItems > 0
BEGIN

	IF @FixedItems = 0
	BEGIN
		SELECT @ServiceCalloutCharge = ISNULL(COALESCE(ContractBillingItem.PartsCharge, CASE WHEN @Quality = 1 THEN BillingItems.IDraughtRetailPrice ELSE BillingItems.BMSRetailPrice END), 0) + ISNULL(COALESCE(ContractBillingItem.LabourCharge, BillingItems.LabourCharge), 0)
		FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
		LEFT JOIN (SELECT BillingItemID, PartsCharge, LabourCharge FROM dbo.ContractBillingItems WHERE BillingItemID = @ServiceCalloutChargeID AND ContractID = @ContractID) AS ContractBillingItem ON ContractBillingItem.BillingItemID = BillingItems.[ID]
		WHERE BillingItems.[ID] = @ServiceCalloutChargeID

		UPDATE dbo.Calls
		SET StandardLabourCharge = @ServiceCalloutCharge
		WHERE [ID] = @CallID
		
		SELECT @LabourMinutes = SUM(LabourMinutes)
		FROM CallBillingItems
		WHERE CallID = @CallID
		AND LabourTypeID > 0
		
		IF @LabourMinutes > 60
		BEGIN
			SELECT @AdditionalLabourCharge = ISNULL(COALESCE(ContractBillingItem.PartsCharge, CASE WHEN @Quality = 1 THEN BillingItems.IDraughtRetailPrice ELSE BillingItems.BMSRetailPrice END), 0) + ISNULL(COALESCE(ContractBillingItem.LabourCharge, BillingItems.LabourCharge), 0)
			FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
			LEFT JOIN (SELECT BillingItemID, PartsCharge, LabourCharge FROM dbo.ContractBillingItems WHERE BillingItemID = @AdditionalLabour AND ContractID = @ContractID) AS ContractBillingItem ON ContractBillingItem.BillingItemID = BillingItems.[ID]
			WHERE BillingItems.[ID] = @AdditionalLabour

			SET @AdditionalLabourQuantity = CEILING(CAST(@LabourMinutes - 60 AS FLOAT) / 30.0)
			
			UPDATE dbo.Calls
			SET AdditionalLabourCharge = @AdditionalLabourCharge * @AdditionalLabourQuantity
			WHERE [ID] = @CallID
		
		END

	END
	ELSE
	BEGIN
		IF @VariableItems > 0
		BEGIN
			SELECT @AdditionalLabourCharge = ISNULL(COALESCE(ContractBillingItem.PartsCharge, CASE WHEN @Quality = 1 THEN BillingItems.IDraughtRetailPrice ELSE BillingItems.BMSRetailPrice END), 0) + ISNULL(COALESCE(ContractBillingItem.LabourCharge, BillingItems.LabourCharge), 0)
			FROM [SQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems
			LEFT JOIN (SELECT BillingItemID, PartsCharge, LabourCharge FROM dbo.ContractBillingItems WHERE BillingItemID = @AdditionalLabour AND ContractID = @ContractID) AS ContractBillingItem ON ContractBillingItem.BillingItemID = BillingItems.[ID]
			WHERE BillingItems.[ID] = @AdditionalLabour

			SELECT @VariableLabourMinutes = SUM(LabourMinutes)
			FROM CallBillingItems
			WHERE CallID = @CallID
			AND LabourTypeID = 2
			
			SET @AdditionalLabourQuantity = CEILING(CAST(@VariableLabourMinutes AS FLOAT) / 30.0)
						
			UPDATE dbo.Calls
			SET AdditionalLabourCharge = @AdditionalLabourCharge * @AdditionalLabourQuantity
			WHERE [ID] = @CallID
			
		END
	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshCallLabourCharges] TO PUBLIC
    AS [dbo];

