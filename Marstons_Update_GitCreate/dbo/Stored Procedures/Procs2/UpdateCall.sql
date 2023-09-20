CREATE PROCEDURE [dbo].[UpdateCall]
(
	@CallID		INT,
	@PriorityID	INT,
	@VisitedOn	DATETIME = NULL,
	@POConfirmed	DATETIME,
	@AuthCode	VARCHAR(255)
)

AS

SET NOCOUNT ON

IF YEAR(@POConfirmed) > 2000
BEGIN
	UPDATE dbo.Calls
	SET POConfirmed = @POConfirmed
	WHERE [ID] = @CallID
END

UPDATE dbo.Calls
SET	PriorityID = @PriorityID,
	VisitedOn = @VisitedOn,
	AuthCode = @AuthCode
WHERE [ID] = @CallID

--Refresh call on Handheld database if applicable
EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCall] TO PUBLIC
    AS [dbo];

