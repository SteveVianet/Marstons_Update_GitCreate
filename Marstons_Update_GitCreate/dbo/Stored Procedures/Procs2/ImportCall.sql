---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE ImportCall
(
	@CallID	INT,
	@SiteID	VARCHAR(255),
	@NewCallID	INT OUTPUT,
	@CustomerID	INT OUTPUT,
	@IsNucleus	BIT
)

AS

SELECT @CustomerID = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

/********************************************************
* Variable declarations
********************************************************/
DECLARE @EDISID		INT
DECLARE @StatusID	INT

DECLARE @OldCallsRaisedDate 	AS DATETIME,
	@OldCallsRaisedBy 	AS VARCHAR(1024),
	@OldCallsReportedBy 	AS VARCHAR(1024),
	@OldCallsContractorID	AS INT,
	@OldCallsConJobRef	AS VARCHAR(1024),
	@OldCallsPOConfDate	AS DATETIME,
	@OldCallsVisitDate	AS DATETIME,
	@OldCallsClosingDate	AS DATETIME,
	@OldCallsClosedBy	AS VARCHAR(1024),
	@OldCallsSignedBy	AS VARCHAR(1024),
	@OldCallsAuthCode	AS VARCHAR(1024),
	@OldCallsComment	AS VARCHAR(8000)


SET NOCOUNT ON



/********************************************************
* Get EDISID
********************************************************/
SELECT	@EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID


/********************************************************
* Get call details
********************************************************/
SELECT	@OldCallsRaisedDate	= OldCallsRaisedDate,
	@OldCallsRaisedBy	= OldCallsRaisedBy,
	@OldCallsReportedBy	= OldCallsReportedBy,
	@OldCallsContractorID	= OldCallsContractorID,
	@OldCallsConJobRef	= OldCallsConJobRef,
	@OldCallsPOConfDate	= OldCallsPOConfDate,
	@OldCallsVisitDate	= OldCallsVisitDate,
	@OldCallsClosingDate	= OldCallsClosingDate,
	@OldCallsClosedBy	= OldCallsClosedBy,
	@OldCallsSignedBy	= OldCallsSignedBy,
	@OldCallsAuthCode	= OldCallsAuthCode,
	@OldCallsComment	= OldCallsComment,
	@StatusID		= OldCallsNewStatusID
FROM [SQL1\SQL1].TestCalls.dbo.OldCalls
WHERE CallID = @CallID

/********************************************************
* Use Nucleus engineer if required
********************************************************/
IF @IsNucleus = 1
BEGIN
	SET @OldCallsContractorID = 54
END

/********************************************************
* Insert call record
********************************************************/
INSERT INTO Calls
(EDISID, CallTypeID, RaisedOn, RaisedBy, ReportedBy, EngineerID, ContractorReference, PriorityID, POConfirmed, 
VisitedOn, ClosedOn, ClosedBy, SignedBy, AuthCode, POStatusID, SalesReference)
VALUES
(@EDISID, 1, @OldCallsRaisedDate, @OldCallsRaisedBy, @OldCallsReportedBy, @OldCallsContractorID, '', 1, @OldCallsPOConfDate, 
@OldCallsVisitDate, @OldCallsClosingDate, @OldCallsClosedBy, @OldCallsSignedBy, @OldCallsAuthCode, 1, NULL)

SET @NewCallID = @@IDENTITY



/********************************************************
* Set call status
********************************************************/
INSERT INTO CallStatusHistory
(CallID, StatusID, ChangedOn, ChangedBy)
VALUES
(@NewCallID, @StatusID, @OldCallsRaisedDate, @OldCallsRaisedBy)


/********************************************************
* Add call comment
********************************************************/
INSERT INTO CallComments
(CallID, Comment, CommentBy, SubmittedOn)
VALUES
(@NewCallID, @OldCallsComment, @OldCallsRaisedBy, @OldCallsRaisedDate)


/********************************************************
* Add call fault if call is a Nucleus call
********************************************************/
IF @IsNucleus = 1
BEGIN
	INSERT INTO CallFaults
	(CallID, FaultTypeID, AdditionalInfo)
	VALUES
	(@NewCallID, 22, '')
END

/********************************************************
* Mark call as imported
********************************************************/
UPDATE [SQL1\SQL1].TestCalls.dbo.Calls
SET Imported = 1
WHERE CallID = @CallID

