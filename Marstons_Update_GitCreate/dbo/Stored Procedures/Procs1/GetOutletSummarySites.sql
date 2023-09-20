---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetOutletSummarySites
(
	@ScheduleDescription	VARCHAR(255)
)

AS

DECLARE @ScheduleID INT

SELECT @ScheduleID = [ID]
FROM dbo.Schedules WHERE [Description] = @ScheduleDescription

SELECT Sites.SiteID, Sites.[Name] AS SiteName, SiteOnline
FROM dbo.ScheduleSites
JOIN dbo.Sites
ON Sites.EDISID = ScheduleSites.EDISID
WHERE ScheduleID = @ScheduleID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutletSummarySites] TO PUBLIC
    AS [dbo];

