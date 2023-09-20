CREATE PROCEDURE [dbo].[zRS_SiteInfoPackVolume]
(
      @Site VARCHAR(60) = NULL,     
      @From DATETIME    = NULL,
      @To   DATETIME    = NULL
)
AS
SET DATEFIRST 1
SELECT     Company.PropertyValue AS Company, dbo.Sites.SiteID, dbo.PeriodCacheTradingDispense.TradingDay, DATEADD(dd, - (DATEPART(dw, dbo.PeriodCacheTradingDispense.TradingDay) - 1), 
                      dbo.PeriodCacheTradingDispense.TradingDay) AS WeekCommencing,
                      ProductCategories.Description AS Category, Products.Description AS Product, SUM(dbo.PeriodCacheTradingDispense.Volume) AS Volume, dbo.Sites.Name, 
                      dbo.Sites.Address1, dbo.Sites.Address2, dbo.Sites.Address3, dbo.Sites.Address4, dbo.Sites.PostCode, dbo.Sites.InstallationDate, 
                      dbo.Sites.Quality, SiteDailyQuality.Quantity, SiteDailyQuality.QuantityTempInSpec,SiteDailyQuality.QuantityTempInAmber, SiteDailyQuality.QuantityTempOutOfSpec, DATEPART(DW, dbo.PeriodCacheTradingDispense.TradingDay) AS [DayOfWeek]
FROM         dbo.PeriodCacheTradingDispense INNER JOIN
                      dbo.Configuration AS Company ON Company.PropertyName = 'Company Name' INNER JOIN
                      dbo.Sites ON Sites.EDISID = PeriodCacheTradingDispense.EDISID INNER JOIN
                      dbo.Products ON Products.ID = PeriodCacheTradingDispense.ProductID INNER JOIN
                      dbo.ProductCategories ON ProductCategories.ID = Products.CategoryID
                      
                      LEFT JOIN (

            SELECT PeriodCacheQuality.EDISID,
                        ProductID,
                        TradingDay,
                        SUM(Quantity) AS Quantity,
                        SUM(QuantityInSpec) AS QuantityTempInSpec,
                        SUM(QuantityInAmber) AS QuantityTempInAmber,
                        SUM(QuantityOutOfSpec) AS QuantityTempOutOfSpec
            FROM PeriodCacheQuality
            JOIN Sites ON Sites.EDISID = PeriodCacheQuality.EDISID
            WHERE Sites.SiteID = @Site
            AND TradingDay BETWEEN @From AND @To
            GROUP BY PeriodCacheQuality.EDISID, ProductID, TradingDay

) AS SiteDailyQuality ON SiteDailyQuality.EDISID = PeriodCacheTradingDispense.EDISID AND
                                         SiteDailyQuality.ProductID = Products.ID AND
                                         SiteDailyQuality.TradingDay = PeriodCacheTradingDispense.TradingDay

WHERE     (dbo.Sites.SiteID = @Site) AND (dbo.PeriodCacheTradingDispense.TradingDay BETWEEN @From AND @To) AND (dbo.Sites.Hidden = 0)
GROUP BY dbo.PeriodCacheTradingDispense.TradingDay,dbo.Sites.SiteID,Products.Description ,ProductCategories.Description,Company.PropertyValue,dbo.Sites.Name, 
                      dbo.Sites.Address1, dbo.Sites.Address2, dbo.Sites.Address3, dbo.Sites.Address4, dbo.Sites.PostCode, dbo.Sites.InstallationDate, 
                     dbo.Sites.Quality, SiteDailyQuality.Quantity, SiteDailyQuality.QuantityTempInSpec, SiteDailyQuality.QuantityTempInAmber, SiteDailyQuality.QuantityTempOutOfSpec

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_SiteInfoPackVolume] TO PUBLIC
    AS [dbo];

