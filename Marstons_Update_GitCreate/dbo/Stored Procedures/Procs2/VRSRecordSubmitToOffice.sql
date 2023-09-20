CREATE PROCEDURE [dbo].[VRSRecordSubmitToOffice]
(
	@VisitNoteID	INT
)

AS

UPDATE VisitRecords
SET	ClosedByCAM = 1,
	DateSubmitted = GETDATE()
WHERE [ID] = @VisitNoteID
AND Deleted = 0

EXEC [dbo].[VRSRecordVerify] @VisitNoteID, 1
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[VRSRecordSubmitToOffice] TO PUBLIC
    AS [dbo];

