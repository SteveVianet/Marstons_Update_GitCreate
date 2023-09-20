---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddSiteClosingHour
(
	@EDISID	INT,
	@WeekDay TINYINT,
	@HourOfDay TINYINT
)

AS

INSERT INTO SiteClosingHours
(EDISID, [WeekDay], HourOfDay)
VALUES
(@EDISID, @WeekDay, @HourOfDay)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteClosingHour] TO PUBLIC
    AS [dbo];

