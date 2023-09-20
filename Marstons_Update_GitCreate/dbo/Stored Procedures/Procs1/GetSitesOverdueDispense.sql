CREATE PROCEDURE [dbo].[GetSitesOverdueDispense]
	@From		DATETIME,
	@To			DATETIME,
	@EDISID		INT
AS

SET NOCOUNT ON;

SELECT	Sites.EDISID,
		Sites.SiteID,
		ISNULL(TotalDispense, 0) AS TotalDispense,
		ISNULL(OverdueDispense, 0) AS OverdueDispense,
		0 AS OverduePercentage,
		ISNULL([Date], GETDATE()) AS [Date],
		Owners.CleaningAmberPercentTarget,
		Owners.CleaningRedPercentTarget
FROM Sites
JOIN Owners ON Sites.OwnerID = Owners.ID
INNER JOIN UserSites ON Sites.EDISID = UserSites.EDISID
LEFT OUTER JOIN (
	SELECT	EDISID,
		SUM(PeriodCacheCleaningDispense.TotalDispense) AS TotalDispense,
		SUM(PeriodCacheCleaningDispense.OverdueCleanDispense) AS OverdueDispense,
		PeriodCacheCleaningDispense.[Date]
	FROM PeriodCacheCleaningDispense 
	JOIN ProductCategories ON ProductCategories.ID = PeriodCacheCleaningDispense.CategoryID
		AND ProductCategories.IncludeInLineCleaning = 1 
	WHERE PeriodCacheCleaningDispense.[Date] BETWEEN @From AND @To
	GROUP BY EDISID, [Date]
) AS PeriodCleaningPercentage ON PeriodCleaningPercentage.EDISID = Sites.EDISID
WHERE Sites.EDISID = @EDISID
GROUP BY Sites.EDISID,
		Sites.SiteID, 
		TotalDispense,
		OverdueDispense,
		[Date],
		CleaningAmberPercentTarget,
		CleaningRedPercentTarget
ORDER By [Date]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesOverdueDispense] TO PUBLIC
    AS [dbo];

