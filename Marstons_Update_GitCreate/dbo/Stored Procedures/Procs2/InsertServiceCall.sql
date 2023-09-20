CREATE PROCEDURE [dbo].[InsertServiceCall] 
(
	@EDISID				INT,
	@CallTypeID			INT,
	@RaisedOn			DATETIME,
	@RaisedBy			VARCHAR(255),
	@ReportedBy			VARCHAR(255),
	@EngineerID			INT = NULL,
	@ContractorReference	VARCHAR(255) = NULL,
	@PriorityID			INT,
	@POConfirmed		DATETIME = NULL,
	@VisitedOn			DATETIME = NULL,
	@ClosedOn			DATETIME = NULL,
	@ClosedBy			VARCHAR(255) = NULL,
	@SignedBy			VARCHAR(255) = NULL,
	@AuthCode			VARCHAR(255) = NULL,
	@POStatusID			INT,
	@SalesReference		VARCHAR(255) = NULL,
	@InvoicedOn			DATETIME = NULL,
	@InvoicedBy			VARCHAR(255) = NULL,
	@WorkDetailComment	TEXT = NULL,
	@AbortReasonID		INT,
	@AbortDate			DATETIME = NULL,
	@AbortUser			VARCHAR(255) = NULL,
	@AbortCode			VARCHAR(255) = NULL,
	@CustomerAbortCode	VARCHAR(255) = NULL,
	@TelecomReference	VARCHAR(255) = NULL,
	@DaysOnHold			INT,
	@OverrideSLA		INT,
	@ID					INT OUTPUT
)
AS

INSERT INTO dbo.Calls
	(EDISID, CallTypeID, RaisedOn, RaisedBy, ReportedBy, EngineerID, ContractorReference, PriorityID, POConfirmed, VisitedOn, ClosedOn, ClosedBy, SignedBy, AuthCode, POStatusID, SalesReference, InvoicedOn, InvoicedBy, WorkDetailComment, AbortReasonID, AbortDate, AbortUser, AbortCode, CustomerAbortCode, TelecomReference, DaysOnHold, OverrideSLA)
VALUES
	(@EDISID, @CallTypeID, @RaisedOn, @RaisedBy, @ReportedBy, @EngineerID, @ContractorReference, @PriorityID, @POConfirmed, @VisitedOn, @ClosedOn, @ClosedBy, @SignedBy, @AuthCode, @POStatusID, @SalesReference, @InvoicedOn, @InvoicedBy, @WorkDetailComment, @AbortReasonID, @AbortDate, @AbortUser, @AbortCode, @CustomerAbortCode, @TelecomReference, @DaysOnHold, @OverrideSLA)
	
SELECT @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertServiceCall] TO PUBLIC
    AS [dbo];

