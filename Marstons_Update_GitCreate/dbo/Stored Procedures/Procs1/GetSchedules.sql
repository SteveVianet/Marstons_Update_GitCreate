---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSchedules
(
	@GetAllSchedules	BIT = 0
)

AS

SELECT 	[ID],
	[Description],
	[Public],
	ExpiryDate
FROM dbo.Schedules
WHERE((UPPER(Owner) = UPPER(SYSTEM_USER) OR [Public] = 1) OR @GetAllSchedules = 1)
AND (ExpiryDate >= GETDATE() OR ExpiryDate IS NULL)
ORDER BY UPPER(SUBSTRING([Description], CHARINDEX(':', [Description])+1, LEN([Description])))
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSchedules] TO PUBLIC
    AS [dbo];

