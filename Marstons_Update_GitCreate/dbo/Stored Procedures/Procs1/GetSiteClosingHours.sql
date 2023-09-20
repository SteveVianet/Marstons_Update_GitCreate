---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteClosingHours
(
	@EDISID	INT
)

AS

SELECT	EDISID,
	[WeekDay],
	HourOfDay
FROM SiteClosingHours
WHERE EDISID = @EDISID
ORDER BY [WeekDay], HourOfDay


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteClosingHours] TO PUBLIC
    AS [dbo];

