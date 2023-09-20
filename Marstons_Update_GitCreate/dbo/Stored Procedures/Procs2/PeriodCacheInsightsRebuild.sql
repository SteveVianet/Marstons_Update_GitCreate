CREATE PROCEDURE dbo.PeriodCacheInsightsRebuild
(
	@From	DATE = NULL
)
AS

DECLARE @EDISID INT = NULL -- NULL to do all sites

IF @From IS NULL
BEGIN
	SET @From = DATEADD(MONTH, -1, GETDATE())
END

DECLARE @DBID INT = (SELECT PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID')

DELETE FROM [SQL1\SQL1].Insights.dbo.Benchmarking WHERE WeekCommencing >= @From AND DatabaseID = @DBID AND (EDISID = @EDISID OR @EDISID IS NULL)

INSERT INTO [SQL1\SQL1].Insights.dbo.Benchmarking
(DatabaseID, OwnerID, OwnerName, EDISID, SiteID, SiteName, WeekCommencing, ProductCategoryID, ProductCategory, CleanTotalDispense, CleanDispense, DueCleanDispense, OverdueCleanDispense, TempTotalDispense, InTempSpecDispense, InToleranceTempSpecDispense, OutTempSpecDispense)
SELECT  @DBID AS DatabaseID,
		Sites.OwnerID,
		Owners.Name AS OwnerName,
		COALESCE(Clean.EDISID, Temp.EDISID) AS EDISID,
		Sites.SiteID,
		Sites.Name AS SiteName,
		COALESCE(Clean.Date, Temp.Date) AS WeekCommencing,
		COALESCE(Clean.CategoryID, Temp.CategoryID) AS ProductCategoryID,
		ProductCategories.Description AS ProductCategory,
		Clean.TotalDispense AS CleanTotalDispense,
		Clean.CleanDispense AS CleanDispense,
		Clean.DueCleanDispense AS DueCleanDispense,
		Clean.OverdueCleanDispense AS OverdueCleanDispense,
		Temp.TotalDispense AS TempTotalDispense,
		Temp.InSpec AS InTempSpecDispense,
		Temp.InTolerance AS InToleranceTempSpecDispense,
		Temp.OutSpec AS OutTempSpecDispense
FROM PeriodCacheCleaningDispense AS Clean
-- Hmm... does this need to be a full join?  What if we have Temps but no cleaning?  Possible?!
LEFT JOIN PeriodCacheTemperature AS Temp ON Temp.EDISID = Clean.EDISID AND Temp.Date = Clean.Date AND Temp.CategoryID = Clean.CategoryID
JOIN Sites ON Sites.EDISID = COALESCE(Clean.EDISID, Temp.EDISID)
JOIN ProductCategories ON ProductCategories.ID = COALESCE(Clean.CategoryID, Temp.CategoryID)
JOIN Owners ON Owners.ID = Sites.OwnerID
WHERE (COALESCE(Clean.EDISID, Temp.EDISID) = @EDISID OR @EDISID IS NULL)
AND COALESCE(Clean.Date, Temp.Date) >= @From
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheInsightsRebuild] TO PUBLIC
    AS [dbo];

