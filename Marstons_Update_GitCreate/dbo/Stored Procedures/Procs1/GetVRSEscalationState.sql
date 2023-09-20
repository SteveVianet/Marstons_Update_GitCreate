CREATE PROCEDURE [dbo].[GetVRSEscalationState]
(
	@VisitNoteID	INT,
	@Escalated BIT OUTPUT,
	@IncludeCompletedNotes BIT = 0
)

AS

SET NOCOUNT ON
DECLARE @EscalateToUserType INT
DECLARE @IsCompleted INT
SET @EscalateToUserType = 0
SET @Escalated = 0


SELECT @IsCompleted = CompletedByCustomer
FROM VisitRecords
WHERE ID = @VisitNoteID

IF @IsCompleted = 0 OR @IncludeCompletedNotes = 1
BEGIN
	SET @EscalateToUserType = dbo.fnGetEscalationRecipientType(@VisitNoteID)
END

IF @EscalateToUserType > 0
BEGIN
	SET @Escalated = 1
END
	

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVRSEscalationState] TO PUBLIC
    AS [dbo];

