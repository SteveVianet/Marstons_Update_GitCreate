---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteSiteClosingHour
(
	@EDISID	INT,
	@WeekDay TINYINT,
	@HourOfDay TINYINT
)

AS

DELETE FROM SiteClosingHours
WHERE EDISID = @EDISID
AND [WeekDay] = @WeekDay
AND HourOfDay = @HourOfDay


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteClosingHour] TO PUBLIC
    AS [dbo];

