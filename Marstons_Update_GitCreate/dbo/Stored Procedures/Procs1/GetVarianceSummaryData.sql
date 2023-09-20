---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetVarianceSummaryData
(
	@StartDate		DATETIME,
	@EndDate		DATETIME,
	@ScheduleDescription	VARCHAR(50)
)

AS

SET NOCOUNT ON

DECLARE @ScheduleID	INT
DECLARE @TiedDispensed	TABLE(	TiedDispensedSiteID 	VARCHAR(50), 
				TiedDispensedQuantity 	FLOAT,
				TiedDispensedDate	DATETIME)
DECLARE @TiedDelivered	TABLE(	TiedDeliveredSiteID 	VARCHAR(50), 
				TiedDeliveredQuantity 	FLOAT,
				TiedDeliveredDate	DATETIME)
DECLARE @SiteDates	TABLE(	SiteDatesSiteID		VARCHAR(50),
				SiteDatesDate		DATETIME)

SET DATEFIRST 1

SELECT @ScheduleID = [ID]
FROM dbo.Schedules
WHERE [Description] = @ScheduleDescription

INSERT INTO @SiteDates
SELECT SiteID, [Date] FROM dbo.fnSiteDates(@StartDate, @EndDate, @ScheduleID)

INSERT INTO @TiedDispensed
SELECT SiteID, Quantity, [Date] FROM fnVarianceSummaryDispensed(@StartDate, @EndDate, @ScheduleID, 1)

INSERT INTO @TiedDelivered
SELECT SiteID, Quantity, [Date] FROM fnVarianceSummaryDelivered(@StartDate, @EndDate, @ScheduleID, 1)

SELECT	SiteDatesSiteID AS SiteID,
		Sites.[Name] AS SiteName,
		Sites.Address3 AS Town,
		SiteDatesDate AS [Date],
		ISNULL(TiedDispensedQuantity, 0) AS SumOfTiedDispensed,
		ISNULL(TiedDeliveredQuantity, 0) AS SumOfTiedDelivered,
		ISNULL(TiedDeliveredQuantity, 0) - ISNULL(TiedDispensedQuantity, 0) AS SumOfTiedVariance,
		CASE WHEN SiteDatesDate < Sites.SiteOnline THEN 1 ELSE 0 END AS Offline,
		Sites.SiteOnline
FROM @SiteDates
LEFT OUTER JOIN @TiedDispensed
	ON	TiedDispensedSiteID = SiteDatesSiteID
	AND	TiedDispensedDate = SiteDatesDate
LEFT OUTER JOIN @TiedDelivered
	ON	TiedDeliveredSiteID = SiteDatesSiteID
	AND	TiedDeliveredDate = SiteDatesDate
INNER JOIN dbo.Sites
	ON Sites.SiteID = SiteDatesSiteID
--GROUP BY 	SiteDatesSiteID, SiteDatesDate, Sites.[Name], Sites.Address3, Sites.SiteOnline
ORDER BY 	SiteDatesSiteID, SiteDatesDate


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVarianceSummaryData] TO PUBLIC
    AS [dbo];

