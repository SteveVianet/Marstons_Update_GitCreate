CREATE PROCEDURE [dbo].[VRSRecordWebSiteMarkAsCompleted]
(
	@VisitNoteID		INT,
	@UserID		INT = NULL,
	@ActionTaken		INT,
	@CustomerComment	TEXT,
	@Damages		MONEY,
	@PartialComment	TEXT
)

AS

DECLARE @HasDamages BIT

IF @Damages > 0
	SET @HasDamages = 1
ELSE
	SET @HasDamages = 0


UPDATE VisitRecords
SET	CompletedByCustomer = 1,
	CompletedDate = GETDATE(),
	BDMID = @UserID,
	BDMComment = @CustomerComment,
	BDMCommentDate = GETDATE(),
	BDMDamagesIssuedValue = @Damages,
	BDMDamagesIssued = @HasDamages,
	BDMPartialReason = @PartialComment,
	BDMActionTaken = @ActionTaken
	
WHERE [ID] = @VisitNoteID AND Deleted = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VRSRecordWebSiteMarkAsCompleted] TO PUBLIC
    AS [dbo];

