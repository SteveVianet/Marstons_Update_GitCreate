

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [art].[GetLastTradingDaySummaryUSByProduct]
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
	dda.Pump AS [Tap],
	dp.[Description] AS [Product_Name],	
	ROUND(AVG(((dda.AverageTemperature * 9) / 5) + 32), 2) AS [Average_Temperature], -- Converted to Fahrenheit from celcius
	ROUND(SUM(dda.Pints * 19.2152), 2) AS [Total_Poured_(Oz)], -- Converted to US Oz from Imperial Pints
	ROUND(SUM(dda.EstimatedDrinks), 2) AS [Est._Beer_Volume_Poured_(Oz)], -- Converted to US Oz from Imperial Pints
	ROUND(Sold * 19.2152, 2) AS [Total_POS_Sold_(Oz)],
	[7Days].Total_Poured_Oz AS [Last_7_Days],
	[30Days].Total_Poured_Oz AS [Last_30_Days]
FROM [dbo].DispenseActions dda 
	JOIN dbo.Sites ds ON dda.EDISID = ds.EDISID
	JOIN dbo.Products dp ON dda.Product = dp.ID
	JOIN dbo.WebSiteTLTillYield dwty ON dda.EDISID = dwty.EDISID AND dp.[Description] = dwty.Product
	JOIN
	(
		SELECT
			ds.SiteID,
			ds.Name,
			dp.[Description] AS [Product_Name],
			ROUND(SUM(dda.Pints * 19.2152), 2) AS [Total_Poured_Oz]
		FROM [dbo].DispenseActions dda 
			JOIN dbo.Sites ds ON dda.EDISID = ds.EDISID
			JOIN dbo.Products dp ON dda.Product = dp.ID
			LEFT JOIN dbo.WebSiteTLTillYield dwty ON dda.EDISID = dwty.EDISID AND dp.[Description] = dwty.Product
		WHERE ds.SiteID = @Site
			AND dda.TradingDay <= @EndDay 
			AND dda.TradingDay >= DATEADD(DAY, DATEDIFF(DAY, 0, @EndDay), -7)
			AND dda.LiquidType = 2
		GROUP BY ds.SiteID, ds.Name, [Description]
	) AS [7Days] ON ds.SiteID = [7Days].SiteID AND ds.Name = [7Days].Name AND dp.[Description] = [7Days].Product_Name
	JOIN
	(
		SELECT
			ds.SiteID,
			ds.Name,
			dp.[Description] AS [Product_Name],
			ROUND(SUM(dda.Pints * 19.2152), 2) AS [Total_Poured_Oz]
		FROM [dbo].DispenseActions dda 
			JOIN dbo.Sites ds ON dda.EDISID = ds.EDISID
			JOIN dbo.Products dp ON dda.Product = dp.ID
			LEFT JOIN dbo.WebSiteTLTillYield dwty ON dda.EDISID = dwty.EDISID AND dp.[Description] = dwty.Product
		WHERE ds.SiteID = @Site
			AND dda.TradingDay <= @EndDay 
			AND dda.TradingDay >= DATEADD(DAY, DATEDIFF(DAY, 0, @EndDay), -30)
			AND dda.LiquidType = 2
		GROUP BY ds.SiteID, ds.Name, [Description]
	) AS [30Days] ON ds.SiteID = [30Days].SiteID AND ds.Name = [30Days].Name AND dp.[Description] = [30Days].Product_Name
WHERE ds.SiteID = @Site
	AND dda.TradingDay = @EndDay 
	AND dda.LiquidType = 2
GROUP BY ds.SiteID, ds.Name, TradingDay, dda.Product, [Description], Pump, Sold, [7Days].Total_Poured_Oz, [30Days].Total_Poured_Oz
ORDER BY [Date], Tap


END



GO
GRANT EXECUTE
    ON OBJECT::[art].[GetLastTradingDaySummaryUSByProduct] TO PUBLIC
    AS [dbo];

