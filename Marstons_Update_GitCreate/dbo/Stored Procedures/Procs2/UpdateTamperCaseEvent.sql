CREATE PROCEDURE [dbo].[UpdateTamperCaseEvent]
(
	@CaseID		INTEGER,
	@OldDate		DATETIME,
	@NewDate		DATETIME,
	@InternalUserID		INTEGER,
	@StateID		INTEGER,
	@SeverityID		INTEGER,
	@TypeListID		INTEGER,
	@OptionalText		VARCHAR(480),
	@AttachmentsID	INTEGER=NULL,
	@SeverityUserID		INTEGER = NULL,
	@AcceptedBy		VARCHAR(100) = NULL
)
AS

UPDATE 
	dbo.TamperCaseEvents
SET
	EventDate=@NewDate,
	UserID=@InternalUserID,
	StateID=@StateID,
	SeverityID=@SeverityID,
	SeverityUserID=@SeverityUserID,
	TypeListID=@TypeListID,
	[Text]=@OptionalText,
	AttachmentsID=@AttachmentsID,
	AcceptedBy = @AcceptedBy
WHERE
	CaseID=@CaseID AND
	EventDate=@OldDate;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateTamperCaseEvent] TO PUBLIC
    AS [dbo];

