



CREATE PROCEDURE [dbo].[UpdateCallReasonType]
(
	@CallReasonTypeID		INT,
	@ContractID				INT,
	@PriorityID				INT,
	@FlagToFinance			BIT,
	@SLA					INT = NULL,
	@AuthorisationRequired	BIT,
	@SLAForKeyTap			INT
)
AS

SET NOCOUNT ON

DECLARE @OldPriorityID				INT
DECLARE	@OldFlagToFinance			BIT
DECLARE	@OldSLA						INT
DECLARE	@OldSLAForKeyTap			INT
DECLARE	@OldAuthorisationRequired	BIT
DECLARE @ExisitingCallReasonTypeID	INT
DECLARE @CallReasonTypeDescription	VARCHAR(100)
DECLARE @ChangeDescription VARCHAR(8000)

SELECT	@OldPriorityID = PriorityID,
		@OldFlagToFinance = FlagToFinance,
		@OldSLA = SLA,
		@OldSLAForKeyTap = SLAForKeyTap,
		@OldAuthorisationRequired = AuthorisationRequired,
		@ExisitingCallReasonTypeID = CallReasonTypeID
FROM dbo.CallReasonTypes
WHERE CallReasonTypeID = @CallReasonTypeID
AND ContractID = @ContractID

IF @ExisitingCallReasonTypeID IS NULL
BEGIN
	INSERT INTO dbo.CallReasonTypes
	(CallReasonTypeID, ContractID, PriorityID, FlagToFinance, SLA, AuthorisationRequired, SLAForKeyTap)
	VALUES
	(@CallReasonTypeID, @ContractID, @PriorityID, @FlagToFinance, @SLA, @AuthorisationRequired, @SLAForKeyTap)
	
END
ELSE
BEGIN
	UPDATE dbo.CallReasonTypes
	SET PriorityID = @PriorityID,
		FlagToFinance = @FlagToFinance,
		SLA = @SLA,
		AuthorisationRequired = @AuthorisationRequired,
		SLAForKeyTap = @SLAForKeyTap
	WHERE CallReasonTypeID = @CallReasonTypeID
	AND ContractID = @ContractID
	
END

SELECT @CallReasonTypeDescription = ISNULL([Description], '')
FROM [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes
WHERE CallReasonTypes.[ID] = @CallReasonTypeID

IF ISNULL(@OldPriorityID, 0) <> ISNULL(@PriorityID, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @CallReasonTypeDescription + '. ' + 'Priority changed from ' + CAST(ISNULL(@OldPriorityID, 0) AS VARCHAR) + ' to ' + CAST(ISNULL(@PriorityID, 0) AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Call Reason', @ContractID, @ChangeDescription
END

IF ISNULL(@OldFlagToFinance, 0) <> ISNULL(@FlagToFinance, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @CallReasonTypeDescription + '. ' + 'Flag to Finance changed from ' + CAST(ISNULL(@OldPriorityID, 0) AS VARCHAR) + ' to ' + CAST(ISNULL(@PriorityID, 0) AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Call Reason', @ContractID, @ChangeDescription
END

IF ISNULL(@OldSLA, 0) <> ISNULL(@SLA, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @CallReasonTypeDescription + '. ' + 'SLA changed from ' + CAST(ISNULL(@OldSLA, 0) AS VARCHAR) + ' to ' + CAST(ISNULL(@SLA, 0) AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Call Reason', @ContractID, @ChangeDescription
END

IF ISNULL(@OldAuthorisationRequired, 0) <> ISNULL(@AuthorisationRequired, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @CallReasonTypeDescription + '. ' + 'Authorisation Required changed from ' + CAST(ISNULL(@OldSLA, 0) AS VARCHAR) + ' to ' + CAST(ISNULL(@SLA, 0) AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Call Reason', @ContractID, @ChangeDescription
END

IF ISNULL(@OldSLAForKeyTap, 0) <> ISNULL(@SLAForKeyTap, 0)
BEGIN
	SET @ChangeDescription = 'Item: ' + @CallReasonTypeDescription + '. ' + 'SLAForKeyTap changed from ' + CAST(ISNULL(@OldSLAForKeyTap, 0) AS VARCHAR) + ' to ' + CAST(ISNULL(@SLAForKeyTap, 0) AS VARCHAR)
	EXEC dbo.AddContractChangeLog 'Call Reason', @ContractID, @ChangeDescription
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallReasonType] TO PUBLIC
    AS [dbo];

