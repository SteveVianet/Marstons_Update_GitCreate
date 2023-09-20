CREATE PROCEDURE [dbo].[DeleteTamperType]
(
	@TypeID	INTEGER,
	@RefID		INTEGER
)
AS
BEGIN TRANSACTION

DELETE 
FROM TamperCaseEventTypeList
WHERE RefID = @RefID AND TypeID = @TypeID
	

COMMIT TRANSACTION
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteTamperType] TO PUBLIC
    AS [dbo];

