CREATE PROCEDURE [dbo].[DeleteVisitRecord]
(
	@RecordID	INTEGER
)

AS


BEGIN TRANSACTION

	
	-- dont actually delete record just mark it as deleted
	UPDATE dbo.VisitRecords
	SET Deleted = 1 
	WHERE ID = @RecordID
	
	-- Remove any damages attached to the visit record
	--DELETE FROM dbo.VisitDamages
	--WHERE VisitRecordID = @RecordID

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteVisitRecord] TO PUBLIC
    AS [dbo];

