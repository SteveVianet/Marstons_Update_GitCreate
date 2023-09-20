CREATE PROCEDURE [dbo].[MarkCallComplete]
(
	@CallID	INT,
	@VisitStartedOn DATETIME = NULL,
	@VisitEndedOn DATETIME = NULL
)

AS

SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRAN

DECLARE @DisableEmail BIT = 0 -- WARNING: Set this to 0 before Production Release. Set this to 1 to prevent errors on UAT (dbo.SendEmail permission is disabled on UAT).

DECLARE @ContractID INT
DECLARE @CallContractID INT
DECLARE	@FullCostPrice	FLOAT
DECLARE	@FullRetailPrice FLOAT
DECLARE	@VATRate FLOAT
DECLARE	@LabourMinutes	FLOAT
DECLARE	@IsCharged		BIT
DECLARE @LabourTypeID	INT
DECLARE @LastStatus INT
DECLARE @LabourMinutesThreshold FLOAT
DECLARE @InvoiceCostThreshold FLOAT


UPDATE dbo.Calls
SET	ClosedBy = SUSER_SNAME(),
	ClosedOn = GETDATE(),
	VisitStartedOn = @VisitStartedOn,
	VisitEndedOn = @VisitEndedOn,
	VisitedOn = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, @VisitStartedOn)))
WHERE [ID] = @CallID AND @VisitStartedOn IS NOT NULL AND @VisitEndedOn IS NOT NULL

UPDATE dbo.Calls
SET	ClosedBy = SUSER_SNAME(),
	ClosedOn = GETDATE()
WHERE [ID] = @CallID AND @VisitStartedOn IS NULL AND @VisitEndedOn IS NULL

-- If call contract uses BillingItems, add standard Base Unit Cost item
SELECT @ContractID = Calls.ContractID,
	   @LabourMinutesThreshold = ISNULL(Contracts.LabourMinutesThreshold, 0),
	   @InvoiceCostThreshold = ISNULL(Contracts.InvoiceCostThreshold, 0)
FROM Calls
JOIN Sites ON Sites.EDISID = Calls.EDISID
JOIN Contracts ON Contracts.[ID] = Calls.ContractID
WHERE Calls.[ID] = @CallID
AND Contracts.UseBillingItems = 1 AND Calls.UseBillingItems = 1

-- Work-around any corrupt/missing Contract data on the Service Call
-- One last ditch attempt to get a valid Contract
IF @ContractID IS NULL OR @ContractID = 0
BEGIN
    SELECT 
        @ContractID = [SiteContracts].[ContractID],
        @LabourMinutesThreshold = ISNULL(Contracts.LabourMinutesThreshold, 0),
	    @InvoiceCostThreshold = ISNULL(Contracts.InvoiceCostThreshold, 0)
	FROM [dbo].[SiteContracts]
    JOIN [dbo].[Sites] ON [SiteContracts].[EDISID] = [Sites].[EDISID]
    JOIN [dbo].[Calls] ON [Sites].[EDISID] = [Calls].[EDISID]
    JOIN [dbo].[Contracts] ON [Contracts].[ID] = [SiteContracts].[ContractID]
	WHERE [Calls].[ID] = @CallID 
    AND [Contracts].[UseBillingItems] = 1 AND [Calls].[UseBillingItems] = 1
END

IF @ContractID IS NOT NULL
BEGIN
	SELECT @LastStatus = StatusID
	FROM CallStatusHistory
	WHERE [ID] IN
	(
		SELECT MAX(ID)
		FROM CallStatusHistory
		WHERE CallID = @CallID
	)
	
	IF @LastStatus <> 4
	BEGIN
	--JS: The rest of the SQL in this block will close down the call, and re-raise another if necessary
		EXEC dbo.UpdateCallStatus @CallID, 4
		
		DECLARE @Today DATETIME
		DECLARE @SiteCallCount INT
		DECLARE @EDISID INT
		DECLARE @PlanningIssueID INT
		DECLARE @OnHoldSubStatusID INT
		DECLARE @ReduceSLA BIT
		DECLARE @AddToSystemStock INT
		DECLARE @AbortReasonID INT
		DECLARE @IncompleteReasonID INT
		DECLARE @CallTypeID INT
		DECLARE @ReportedBy VARCHAR(100)
		DECLARE @PriorityID INT
		DECLARE @POStatusID INT
		DECLARE @SalesReference VARCHAR(100)
		DECLARE @RaisedOn DATETIME
		DECLARE @RaisedBy VARCHAR(100)
		DECLARE @Quality BIT
		DECLARE @InstallDate DATETIME
		DECLARE @NewCallID INT
		DECLARE @EngineerID INT
		DECLARE @ReRaisedCall BIT = 0
		DECLARE @CallCategoryID INT
		DECLARE @ClosedOn DATETIME
		DECLARE @QuantityForStock INT
		DECLARE @POConfirmed DATETIME
		DECLARE @AuthCode VARCHAR(255)
		DECLARE @IsChargedCount INT
		DECLARE @TotalLabourMinutes FLOAT
		DECLARE @TotalInvoiceCost FLOAT
		DECLARE @InstallCallID INT
		
		SELECT @CallContractID = ContractID
		FROM dbo.Calls
		WHERE [ID] = @CallID
		
		IF (@CallContractID IS NULL OR @CallContractID = 0) AND (@ContractID IS NOT NULL)
		BEGIN
			UPDATE dbo.Calls
			SET ContractID = @ContractID
			WHERE [ID] = @CallID
		END
		
		SET @Today = GETDATE()
		
		SELECT @AddToSystemStock = COUNT(*)
		FROM dbo.CallReasons
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.[ID] = CallReasons.ReasonTypeID
		WHERE CallID = @CallID 
		AND AddToSystemStock = 1
		
		SELECT @QuantityForStock = SUM(CallBillingItems.Quantity)
		FROM dbo.CallBillingItems
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.BillingItems AS BillingItems ON BillingItems.[ID] = CallBillingItems.BillingItemID
		WHERE CallID = @CallID
		AND AddToSystemStock = 1
		
		IF @AddToSystemStock > 0 AND @QuantityForStock > 0
		BEGIN
			DECLARE @DateIn DATETIME
			DECLARE @SystemTypeID INT
			DECLARE @SiteName VARCHAR(100)
			DECLARE @Postcode VARCHAR(25)
			DECLARE @PumpCount INT
			DECLARE @NewSystemStockID INT
			DECLARE @QuantityCount INT
			
			SET @DateIn = GETDATE()
			
			SELECT @InstallDate = Sites.InstallationDate,
				   @SystemTypeID = Sites.SystemTypeID,
				   @EDISID = Sites.EDISID,
				   @SiteName = Sites.Name,
				   @Postcode = Sites.PostCode
			FROM Sites
			JOIN Calls ON Calls.EDISID = Sites.EDISID
			WHERE Calls.[ID] = @CallID
			
			SELECT @PumpCount = COUNT(*)
			FROM PumpSetup
			JOIN Sites ON Sites.EDISID = PumpSetup.EDISID
			JOIN Calls ON Calls.EDISID = Sites.EDISID
			WHERE Calls.[ID] = @CallID
			AND ValidTo IS NULL
		
			SET @QuantityCount = 1
			
			WHILE @QuantityCount <= @QuantityForStock
			BEGIN
				EXEC dbo.AddSystemStock @DateIn, @InstallDate, 0, @SystemTypeID, @CallID, @EDISID, @SiteName, @Postcode, @PumpCount, 0, NULL, @NewSystemStockID OUTPUT
				SET @QuantityCount = @QuantityCount + 1
				
			END
			
		END
		
		SELECT @EDISID = Sites.EDISID,
			   @AbortReasonID = AbortReasonID,
			   @IncompleteReasonID = IncompleteReasonID,
			   @CallTypeID = CallTypeID,
			   @ReportedBy = ReportedBy,
			   @PriorityID = PriorityID,
			   @POStatusID = POStatusID,
			   @SalesReference = SalesReference,
			   @RaisedOn = RaisedOn,
			   @RaisedBy = RaisedBy,
			   @Quality = Quality,
			   @InstallDate = Sites.InstallationDate,
			   @EngineerID = EngineerID,
			   @CallCategoryID = CallCategoryID,
			   @POConfirmed = POConfirmed,
			   @AuthCode = AuthCode,
			   @InstallCallID = InstallCallID
		FROM Calls
		JOIN Sites ON Sites.EDISID = Calls.EDISID
		WHERE [ID] = @CallID
		
		SELECT @SiteCallCount = COUNT(*)
		FROM Calls
		WHERE EDISID = @EDISID
		
		DECLARE @NewSystemInstalled BIT = 0
		SELECT @NewSystemInstalled = 1
		FROM CallReasons
		WHERE CallID = @CallID
		AND ReasonTypeID = 1
		
		IF @SiteCallCount = 1
		BEGIN
			EXEC dbo.UpdateSiteBirthDate @EDISID, @Today
			
		END
		
		IF @CallCategoryID = 4
		BEGIN
			EXEC dbo.UpdateSiteLastInstallationDate @EDISID, @Today
			
		END
		
		IF @NewSystemInstalled = 1
		BEGIN
			EXEC dbo.UpdateSiteInstallationDate @EDISID, @Today
			
		END

		EXEC dbo.UpdateServiceIssuesDateTo @CallID
				
		DECLARE curLinkedBillingItems CURSOR FORWARD_ONLY READ_ONLY FOR
		SELECT DISTINCT LinkedBillingItemID
		FROM dbo.ContractLinkedBillingItems
		WHERE ContractID = @ContractID
		AND BillingItemID IN (SELECT BillingItemID FROM dbo.CallBillingItems WHERE CallID = @CallID)
		
		DECLARE @LinkedBillingItemID INT
		DECLARE @ExistingBillingItemID INT
		
		OPEN curLinkedBillingItems
		FETCH NEXT FROM curLinkedBillingItems INTO @LinkedBillingItemID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @ExistingBillingItemID = NULL
			
			SELECT @ExistingBillingItemID = BillingItemID
			FROM dbo.CallBillingItems
			WHERE CallID = @CallID
			AND BillingItemID = @LinkedBillingItemID
			
			IF @ExistingBillingItemID IS NULL
			BEGIN
				EXEC dbo.AddCallBillingItem @CallID, @LinkedBillingItemID, 1, @FullCostPrice OUTPUT, @FullRetailPrice OUTPUT, @VATRate OUTPUT, @ContractID OUTPUT, @LabourMinutes OUTPUT, @IsCharged OUTPUT, @LabourTypeID OUTPUT

			END
			
			FETCH NEXT FROM curLinkedBillingItems INTO @LinkedBillingItemID
			
		END

		CLOSE curLinkedBillingItems
		DEALLOCATE curLinkedBillingItems

		DECLARE @CompletedPAT BIT = 0
		SELECT @CompletedPAT = 1
		FROM CallBillingItems
		WHERE CallID = @CallID
		AND BillingItemID = 68

		IF @CompletedPAT = 1
		BEGIN
			EXEC dbo.UpdateSiteLastPATDate @EDISID, @Today

		END

		DECLARE @CompletedZ2ElectricalCheck BIT = 0
		SELECT @CompletedZ2ElectricalCheck = 1
		FROM CallBillingItems
		WHERE CallID = @CallID
		AND BillingItemID = 113

		IF @CompletedZ2ElectricalCheck = 1
		BEGIN
			EXEC dbo.UpdateSiteLastElectricalCheckDate @EDISID, @Today

		END
		
		SELECT @OnHoldSubStatusID = CallIncompleteReasons.PlanningIssueID,
			   @ReduceSLA = CallIncompleteReasons.ReduceSLAForRevisit
		FROM Calls
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallIncompleteReasons AS CallIncompleteReasons ON CallIncompleteReasons.[ID] = Calls.IncompleteReasonID
		WHERE Calls.[ID] = @CallID AND @IncompleteReasonID > 0
		
		SELECT @OnHoldSubStatusID = AbortReasons.OnHoldSubStatusID,
			   @ReduceSLA = 0,
			   @PlanningIssueID = 13
		FROM Calls
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.AbortReasons AS AbortReasons ON AbortReasons.[ID] = Calls.AbortReasonID
		WHERE Calls.[ID] = @CallID AND @AbortReasonID > 0 AND @OnHoldSubStatusID IS NULL
		
		IF @AbortReasonID = 0
		BEGIN
			--DMG: Do a delete first to avoid PK errors if a call has been revisited. Brings this procedure in line with the HandHeld system.
			EXEC dbo.DeleteCallBillingItem @CallID, 1
			EXEC dbo.AddCallBillingItem @CallID, 1, 1, @FullCostPrice OUTPUT, @FullRetailPrice OUTPUT, @VATRate OUTPUT, @ContractID OUTPUT, @LabourMinutes OUTPUT, @IsCharged OUTPUT, @LabourTypeID OUTPUT
		
		END
		
		IF @AbortReasonID IN (1,2,4,5) OR @IncompleteReasonID > 0
		BEGIN
			IF @AbortReasonID IN (1,2,4)
			BEGIN
				EXEC dbo.DeleteCallBillingItem @CallID, 87
				EXEC dbo.AddCallBillingItem @CallID, 87, 1, @FullCostPrice OUTPUT, @FullRetailPrice OUTPUT, @VATRate OUTPUT, @ContractID OUTPUT, @LabourMinutes OUTPUT, @IsCharged OUTPUT, @LabourTypeID OUTPUT

			END
			
			IF @ReduceSLA = 0
			BEGIN
				SET @RaisedOn = GETDATE()
				
			END
			
			SET @ReRaisedCall = 1
			
			EXEC dbo.RaiseCall @EDISID, @CallTypeID, @ReportedBy, @PriorityID, 1, -1, @POStatusID, @SalesReference, @NewCallID OUTPUT, @RaisedOn OUTPUT, @RaisedBy OUTPUT, @CallID, @RaisedOn, @Quality, @InstallDate
			EXEC dbo.UpdateCallContractor @NewCallID, @EngineerID
			EXEC dbo.UpdateCall @NewCallID, @PriorityID, NULL, @POConfirmed, @AuthCode
			EXEC dbo.UpdateCallCategoryID @NewCallID, @CallCategoryID
			EXEC dbo.UpdateCallInstallCallID @NewCallID, @InstallCallID

			INSERT INTO dbo.CallReasons
			(CallID, ReasonTypeID, AdditionalInfo)
			SELECT @NewCallID, ReasonTypeID, AdditionalInfo
			FROM CallReasons
			WHERE CallID = @CallID
			
			INSERT INTO dbo.CallComments
			(CallID, EditedOn, SubmittedOn, Comment, CommentBy)
			SELECT @NewCallID, EditedOn, SubmittedOn, Comment, CommentBy
			FROM CallComments
			WHERE [ID] IN
			(
				SELECT MAX([ID])
				FROM CallComments
				WHERE CallID = @CallID
			)
			
			INSERT INTO dbo.CallComments
			(CallID, EditedOn, SubmittedOn, Comment, CommentBy)
			SELECT @NewCallID, EditedOn, SubmittedOn, 'Previous Engineer Comment: ' + CAST(WorkDetailComment AS VARCHAR(MAX)), WorkDetailCommentBy
			FROM CallWorkDetailComments
			WHERE [ID] IN
			(
				SELECT MAX([ID])
				FROM CallWorkDetailComments
				WHERE CallID = @CallID
			)

			INSERT INTO dbo.ServiceIssuesQuality
			(EDISID, CallID, PumpID, ProductID, PrimaryProductID, DateFrom, DateTo, RealPumpID, RealEDISID, CallReasonTypeID)
			SELECT EDISID, @NewCallID, PumpID, ProductID, PrimaryProductID, GETDATE(), NULL, RealPumpID, RealEDISID, CallReasonTypeID
			FROM ServiceIssuesQuality
			WHERE CallID = @CallID

			INSERT INTO dbo.ServiceIssuesYield
			(EDISID, CallID, ProductID, PrimaryProductID, DateFrom, DateTo, RealEDISID, CallReasonTypeID)
			SELECT EDISID, @NewCallID, ProductID, PrimaryProductID, GETDATE(), NULL, RealEDISID, CallReasonTypeID
			FROM ServiceIssuesYield
			WHERE CallID = @CallID

			INSERT INTO dbo.ServiceIssuesEquipment
			(EDISID, CallID, InputID, DateFrom, DateTo, RealEDISID, CallReasonTypeID)
			SELECT EDISID, @NewCallID, InputID, GETDATE(), NULL, RealEDISID, CallReasonTypeID
			FROM ServiceIssuesEquipment
			WHERE CallID = @CallID

			IF @OnHoldSubStatusID > 0
			BEGIN
				EXEC dbo.UpdateCallStatus @NewCallID, 2, @OnHoldSubStatusID
				
			END
			
			IF @PlanningIssueID > 0
			BEGIN
				EXEC dbo.UpdateCallPlanningIssue @NewCallID, @PlanningIssueID
				
			END
			
		END
		ELSE
		BEGIN
			DECLARE @MaintenanceCall BIT = 0
			SELECT @MaintenanceCall = 1
			FROM CallReasons
			WHERE CallID = @CallID
			AND ReasonTypeID = 41

			IF @MaintenanceCall = 1
			BEGIN
				EXEC dbo.UpdateSiteLastMaintenanceDate @EDISID, @Today

			END

		END
		
		SELECT @IsChargedCount = SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END),
			   @TotalLabourMinutes = SUM(LabourMinutes),
			   @TotalInvoiceCost = SUM(FullRetailPrice)
		FROM CallBillingItems
		
		IF (@IsChargedCount > 0) OR (@TotalLabourMinutes > @LabourMinutesThreshold) OR (@TotalInvoiceCost > @InvoiceCostThreshold)
		BEGIN
			EXEC dbo.UpdateCallFlagToFinance @CallID, 1
		END
		
		EXEC dbo.RefreshCallLabourCharges @CallID
		
        IF @DisableEmail = 0
        BEGIN
		    EXEC dbo.GenerateCallClosedEmail @CallID, @ReRaisedCall
        END
	
	END
	
END

COMMIT
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MarkCallComplete] TO PUBLIC
    AS [dbo];

