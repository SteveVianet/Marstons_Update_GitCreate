CREATE PROCEDURE [dbo].[RaiseCall]
(
	@EDISID	INT,
	@CallTypeID	INT,
	@ReportedBy	VARCHAR(255),
	@PriorityID	INT,
	@StatusID	INT,
	@SubStatusID	INT			= -1,
	@POStatusID	INT,
	@SalesReference	VARCHAR(255),
	@NewCallID	INT			OUTPUT,
	@RaisedOn	SMALLDATETIME	OUTPUT,
	@RaisedBy	VARCHAR(255)		OUTPUT,
	@ReRaiseFromCallID INT = NULL,
	@OriginalRaisedOn SMALLDATETIME = NULL,
	@QualitySite BIT = 0,
	@InstallationDate DATETIME = NULL
)

AS

SET NOCOUNT ON

DECLARE @SLA INT
DECLARE @UseBillingItems BIT
DECLARE @ContractID INT

-- Do this so we can raise a call AND set it's status
BEGIN TRANSACTION

-- Original raised on will not be null if the call is re-raised. If not, get the date/time for the raise date
IF @OriginalRaisedOn IS NULL
BEGIN
	SET @OriginalRaisedOn = GETDATE()
END

SELECT @SLA = CASE WHEN Quality = 1 THEN 5 ELSE 7 END
FROM Sites
WHERE EDISID = @EDISID

SELECT @UseBillingItems = Contracts.UseBillingItems, @ContractID = Contracts.[ID]
FROM SiteContracts
JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
WHERE EDISID = @EDISID

-- Add call
IF @RaisedBy IS NULL OR @RaisedBy = ''
BEGIN
	INSERT INTO dbo.Calls(EDISID, RaisedOn, CallTypeID, ReportedBy, PriorityID, POStatusID, SalesReference, ReRaiseFromCallID, OverrideSLA, QualitySite, InstallationDate, UseBillingItems, ContractID)
	VALUES(@EDISID, @OriginalRaisedOn, @CallTypeID, @ReportedBy, @PriorityID, @POStatusID, @SalesReference, @ReRaiseFromCallID, @SLA, @QualitySite, @InstallationDate, @UseBillingItems, @ContractID)
END
ELSE
BEGIN
	INSERT INTO dbo.Calls(RaisedBy, RaisedOn, EDISID, CallTypeID, ReportedBy, PriorityID, POStatusID, SalesReference, ReRaiseFromCallID, OverrideSLA, QualitySite, InstallationDate, UseBillingItems, ContractID)
	VALUES(@RaisedBy, @OriginalRaisedOn, @EDISID, @CallTypeID, @ReportedBy, @PriorityID, @POStatusID, @SalesReference, @ReRaiseFromCallID, @SLA, @QualitySite, @InstallationDate, @UseBillingItems, @ContractID)
END

-- Return new Call ID
SET @NewCallID = @@IDENTITY

-- Check for an error
IF (@@ERROR <> 0) OR (@NewCallID IS NULL)
BEGIN
	ROLLBACK TRANSACTION
	RETURN -1
END

-- Return Username and Date of call
SELECT	@RaisedOn = RaisedOn,
	@RaisedBy = RaisedBy
FROM dbo.Calls
WHERE [ID] = @NewCallID

-- Check for an error
IF (@RaisedOn IS NULL) OR (@RaisedBy IS NULL)
BEGIN
	ROLLBACK TRANSACTION
	RETURN -2
END

-- Set call status
INSERT INTO dbo.CallStatusHistory(CallID, StatusID, SubStatusID)
VALUES (@NewCallID, @StatusID, @SubStatusID)

IF @@ERROR = 0
BEGIN
	COMMIT TRANSACTION
	EXEC dbo.RefreshHandheldCall @NewCallID, 1, 1, 1
	RETURN 0
END
ELSE
BEGIN
	ROLLBACK TRANSACTION
	RETURN -3
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RaiseCall] TO PUBLIC
    AS [dbo];

