---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetRedAlertData
(
	@StartDate		DATETIME,
	@EndDate		DATETIME,
	@ScheduleDescription	VARCHAR(50)
)

AS

DECLARE @ScheduleID	INT

SELECT @ScheduleID = [ID]
FROM dbo.Schedules
WHERE [Description] = @ScheduleDescription

SELECT	Sites.SiteID AS SiteID,
		Sites.[Name] AS SiteName,
		Sites.Address3 AS Town,
		ISNULL(TiedDispensed.Quantity, 0) AS SumOfTiedDispensed,
		ISNULL(TiedDelivered.Quantity, 0) AS SumOfTiedDelivered,
		ISNULL(TiedDelivered.Quantity, 0) - ISNULL(TiedDispensed.Quantity, 0) AS SumOfTiedVariance,
		ISNULL(UntiedDispensed.Quantity, 0) AS SumOfUntiedDispensed,
		ISNULL(UntiedDelivered.Quantity, 0) AS SumOfUntiedDelivered,
		ISNULL(UntiedDelivered.Quantity, 0) - ISNULL(UntiedDispensed.Quantity, 0) AS SumOfUntiedVariance,
		Sites.SiteOnline,
		Sites.Budget
FROM dbo.Sites
JOIN dbo.ScheduleSites
	ON ScheduleSites.EDISID = Sites.EDISID
FULL OUTER JOIN dbo.fnRedAlertDispensed(@StartDate, @EndDate, @ScheduleID, 1) AS TiedDispensed
	ON TiedDispensed.SiteID = Sites.SiteID
FULL OUTER JOIN dbo.fnRedAlertDispensed(@StartDate, @EndDate, @ScheduleID, 0) AS UntiedDispensed
	ON UntiedDispensed.SiteID = Sites.SiteID
FULL OUTER JOIN dbo.fnRedAlertDelivered(@StartDate, @EndDate, @ScheduleID, 1) AS TiedDelivered
	ON TiedDelivered.SiteID = Sites.SiteID
FULL OUTER JOIN dbo.fnRedAlertDelivered(@StartDate, @EndDate, @ScheduleID, 0) AS UntiedDelivered
	ON UntiedDelivered.SiteID = Sites.SiteID
WHERE ScheduleSites.ScheduleID = @ScheduleID
ORDER BY ISNULL(TiedDelivered.Quantity, 0) - ISNULL(TiedDispensed.Quantity, 0)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetRedAlertData] TO PUBLIC
    AS [dbo];

