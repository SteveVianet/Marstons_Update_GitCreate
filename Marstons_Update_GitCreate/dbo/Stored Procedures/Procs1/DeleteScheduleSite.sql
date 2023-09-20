---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteScheduleSite
(
	@ScheduleID	INT,
	@EDISID	INT
)

AS

DELETE FROM dbo.ScheduleSites
WHERE ScheduleID = @ScheduleID
AND EDISID = @EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteScheduleSite] TO PUBLIC
    AS [dbo];

