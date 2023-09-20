
CREATE PROCEDURE [dbo].[UpdateCallNumberOfVisits]
(
	@CallID			INT,
	@NumberOfVisits	INT
)

AS

UPDATE dbo.Calls
SET NumberOfVisits = @NumberOfVisits
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallNumberOfVisits] TO PUBLIC
    AS [dbo];

