CREATE PROCEDURE [dbo].[zRS_SiteInfoPackYield]

(
      @Site VARCHAR(60) = NULL,     
      @From DATETIME    = NULL,
      @To   DATETIME    = NULL
)
AS
SET DATEFIRST 1

SELECT	SiteID
		, DATEADD(dd, - (DATEPART(dw, DispenseDay) - 1), DispenseDay) AS WeekCommencing
		, ProductCategories.Description	AS Category
		, SUM(Quantity)			AS Quantity	
		, SUM(Drinks)			AS Drinks
		

FROM PeriodCacheYield

JOIN Sites				ON	Sites.EDISID = PeriodCacheYield.EDISID
JOIN ProductCategories	ON	ProductCategories.ID = PeriodCacheYield.CategoryID

WHERE SiteID = @Site

AND DispenseDay BETWEEN @From AND @To

GROUP BY
	SiteID
	,DispenseDay
	,ProductCategories.Description

ORDER BY DispenseDay


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_SiteInfoPackYield] TO PUBLIC
    AS [dbo];

