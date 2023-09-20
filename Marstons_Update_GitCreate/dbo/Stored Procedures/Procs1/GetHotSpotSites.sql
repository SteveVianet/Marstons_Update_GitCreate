---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetHotSpotSites
(
	@ScheduleDescription	VARCHAR(50)
)

AS

SELECT 	Sites.SiteID, 
		Sites.[Name] AS SiteName,
		Sites.Address3 AS SiteTown,
		Sites.SiteOnline
FROM dbo.ScheduleSites
JOIN dbo.Schedules ON Schedules.[ID] = ScheduleSites.ScheduleID
JOIN dbo.Sites ON Sites.EDISID = ScheduleSites.EDISID
WHERE Schedules.[Description] = @ScheduleDescription

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHotSpotSites] TO PUBLIC
    AS [dbo];

