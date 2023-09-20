CREATE PROCEDURE [dbo].[AddTamperEvent]
(
	@CaseID		INTEGER, 
	@EventDate		DATETIME, 
	@InternalUserID		INTEGER, 
	@StateID		INTEGER, 
	@SeverityID		INTEGER, 
	@TypeListID		INTEGER, 
	@OptionalText		VARCHAR(480), 
	@AttachmentsID	INTEGER = NULL,
	@SeverityUserID		INTEGER = NULL,
	@AcceptedBy		VARCHAR(100) = NULL
)
AS
BEGIN

INSERT INTO
	dbo.TamperCaseEvents (CaseID, EventDate, UserID, StateID, SeverityID, SeverityUserID, TypeListID, [Text], AttachmentsID, AcceptedBy )
VALUES
	(@CaseID, @EventDate, @InternalUserID, @StateID, @SeverityID, @SeverityUserID, @TypeListID, @OptionalText, @AttachmentsID, @AcceptedBy)	

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddTamperEvent] TO PUBLIC
    AS [dbo];

