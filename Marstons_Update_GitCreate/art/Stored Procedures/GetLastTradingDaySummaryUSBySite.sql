

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [art].[GetLastTradingDaySummaryUSBySite]
	-- Add the parameters for the stored procedure here
	@Site VARCHAR(15),
	@EndDay DATE = NULL
AS
BEGIN

IF @EndDay IS NULL
BEGIN
	SET @EndDay = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), -1)
END

SELECT 
	ds.SiteID,
	ds.Name,
	CONVERT(VARCHAR(10),dda.TradingDay, 110) AS [Date],
	ROUND(SUM(dda.Pints * 19.2152),2) AS [Total_Oz_Poured], -- Converted to US Oz from Imperial Pints
	ROUND((((dwe1.Temperature * 9) / 5) + 32), 2)AS [Avg_Line_Temperature],
	ROUND((((dwe2.Temperature * 9) / 5) + 32), 2)AS [Avg_Cooler_Temperature]
FROM [dbo].DispenseActions dda 
	JOIN dbo.Sites ds ON dda.EDISID = ds.EDISID
	JOIN dbo.Products dp ON dda.Product = dp.ID
	JOIN dbo.WebSiteTLEquipment dwe1 ON dda.EDISID = dwe1.EDISID AND dwe1.EquipmentTypeID = 13 --Line
	JOIN dbo.WebSiteTLEquipment dwe2 ON dda.EDISID = dwe2.EDISID  AND dwe2.EquipmentTypeID = 18 --Cooler
WHERE ds.SiteID = @Site
	AND TradingDay = @EndDay
	AND dda.LiquidType = 2
GROUP BY ds.SiteID, ds.Name, TradingDay, dwe1.Temperature, dwe2.Temperature
ORDER BY [Date]


END



GO
GRANT EXECUTE
    ON OBJECT::[art].[GetLastTradingDaySummaryUSBySite] TO PUBLIC
    AS [dbo];

