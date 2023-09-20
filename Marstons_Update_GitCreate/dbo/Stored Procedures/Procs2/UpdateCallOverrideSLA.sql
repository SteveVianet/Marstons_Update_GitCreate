CREATE PROCEDURE UpdateCallOverrideSLA
(
	@CallID			INT,
	@OverrideSLA		INT
)

AS

UPDATE dbo.Calls
SET OverrideSLA = @OverrideSLA
WHERE [ID] = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallOverrideSLA] TO PUBLIC
    AS [dbo];

