CREATE PROCEDURE [dbo].[HasCallCompletionSheet]

	@CallID INT,
	@Exists BIT OUTPUT

AS

SET NOCOUNT ON
SET @Exists = 0

IF (SELECT COUNT(*) FROM CallCompletionSheets WHERE CallID = @CallID) > 0
BEGIN
	SET @Exists = 1
	
END

RETURN @Exists

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[HasCallCompletionSheet] TO PUBLIC
    AS [dbo];

