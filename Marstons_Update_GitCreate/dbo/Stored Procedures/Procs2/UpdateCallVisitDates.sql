CREATE PROCEDURE [dbo].[UpdateCallVisitDates]
(
	@CallID				INT,
	@VisitStartedOn		DATETIME,
	@VisitEndedOn		DATETIME
)

AS

UPDATE dbo.Calls
SET VisitStartedOn = @VisitStartedOn,
    VisitEndedOn = @VisitEndedOn
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallVisitDates] TO PUBLIC
    AS [dbo];

