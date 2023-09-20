

CREATE Procedure [dbo].[zRS_MarstonsPromo]
AS

SET DATEFIRST 1

SELECT SiteID
		,Name
		,DATEADD(dd, -(DATEPART(dw, TradingDay)-1), TradingDay)		AS WeekCommencing
		,ProductCategories.Description								AS Category
		,Products.Description										AS Product
		,SUM(Volume)+SUM(WastedVolume)								AS TotalVolume

FROM PeriodCacheTradingDispense


JOIN Sites				ON	Sites.EDISID			= PeriodCacheTradingDispense.EDISID
JOIN Products			ON	Products.ID				= PeriodCacheTradingDispense.ProductID
JOIN ProductCategories	ON	ProductCategories.ID	= Products.CategoryID

JOIN ScheduleSites		ON	ScheduleSites.EDISID	= PeriodCacheTradingDispense.EDISID	


WHERE TradingDay > '2012-10-01'

AND ScheduleID = 1672
AND	DATEPART(WEEKDAY,TradingDay) IN (1,2,3,4)

GROUP BY SiteID
,Name
,DATEADD(dd, -(DATEPART(dw, TradingDay)-1), TradingDay)
,ProductCategories.Description
,Products.Description

HAVING DATEADD(dd, -(DATEPART(dw, TradingDay)-1), TradingDay) BETWEEN GETDATE()-190  AND GETDATE()-7
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_MarstonsPromo] TO PUBLIC
    AS [dbo];

