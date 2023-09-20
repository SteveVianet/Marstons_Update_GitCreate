
CREATE PROCEDURE dbo.GetTamperCaseEventAcceptedUsers


AS
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT(AcceptedBy)
	FROM TamperCaseEvents
	WHERE AcceptedBy <> NULL OR AcceptedBy <> ''
	
END