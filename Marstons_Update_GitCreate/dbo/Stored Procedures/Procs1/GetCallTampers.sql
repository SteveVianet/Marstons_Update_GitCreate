---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallTampers
(
	@CallID	INT
)

AS

SELECT	ReasonID,
	Remarks
FROM CallTampers
WHERE CallID = @CallID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallTampers] TO PUBLIC
    AS [dbo];

