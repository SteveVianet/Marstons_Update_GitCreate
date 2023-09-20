CREATE PROCEDURE [dbo].[zRS_GetPeriodCacheCleaning]
(
	@SiteID					VARCHAR(60),
	@From					DATETIME,
	@To						DATETIME
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

SELECT	EDISID,
		Date,
		ProductCategories.Description AS Category,
		CleanDispense,
		DueCleanDispense,
		OverdueCleanDispense
FROM PeriodCacheCleaningDispense
JOIN ProductCategories ON ProductCategories.ID = PeriodCacheCleaningDispense.CategoryID
WHERE EDISID = @EDISID
AND [Date] BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetPeriodCacheCleaning] TO PUBLIC
    AS [dbo];

