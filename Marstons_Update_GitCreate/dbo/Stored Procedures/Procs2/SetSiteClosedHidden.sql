---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[SetSiteClosedHidden]
(
	@EDISID		INT,
	@Closed	BIT,
	@Hidden	BIT,
	@Unassign BIT = 1
)

AS

UPDATE Sites
SET SiteClosed = @Closed,
	Hidden = @Hidden
WHERE EDISID = @EDISID

IF @Unassign = 1
BEGIN
	-- Remove site from any schedules
	DELETE FROM ScheduleSites
	WHERE EDISID = @EDISID
	
	-- Remote site from users
	DELETE FROM UserSites
	WHERE EDISID = @EDISID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetSiteClosedHidden] TO PUBLIC
    AS [dbo];

