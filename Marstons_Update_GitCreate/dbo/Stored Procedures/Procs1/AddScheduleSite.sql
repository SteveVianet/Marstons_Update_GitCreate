---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddScheduleSite
(
	@ScheduleID	INT,
	@EDISID	INT
)

AS

INSERT INTO dbo.ScheduleSites
(ScheduleID, EDISID)
VALUES
(@ScheduleID, @EDISID)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddScheduleSite] TO PUBLIC
    AS [dbo];

