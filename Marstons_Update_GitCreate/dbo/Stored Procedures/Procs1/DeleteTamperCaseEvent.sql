CREATE PROCEDURE [dbo].[DeleteTamperCaseEvent]
(
	@CaseID		INTEGER,
	@EventDate		DATETIME	
)
AS

DELETE FROM 
	dbo.TamperCaseEvents
WHERE
	CaseID=@CaseID AND
	EventDate=@EventDate;
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteTamperCaseEvent] TO PUBLIC
    AS [dbo];

