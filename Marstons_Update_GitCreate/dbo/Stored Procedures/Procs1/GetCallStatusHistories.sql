---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCallStatusHistories
(
	@CallID		INT
)

AS

SELECT	StatusID,
	SubStatusID,
	ChangedOn,
	ChangedBy
FROM CallStatusHistory
WHERE CallID = @CallID
ORDER BY ChangedOn
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallStatusHistories] TO PUBLIC
    AS [dbo];

