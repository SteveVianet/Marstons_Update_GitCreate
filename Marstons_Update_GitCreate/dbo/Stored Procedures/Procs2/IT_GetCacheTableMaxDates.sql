CREATE PROCEDURE IT_GetCacheTableMaxDates

AS

DECLARE @AuditDate DATE
DECLARE @Calls DATE
DECLARE @Cleaning DATE
DECLARE @CleaningDispense DATE
DECLARE @Quality DATE
DECLARE @Sales DATE
DECLARE @Temperature DATE
DECLARE @TradingDispense DATE
DECLARE @Variance DATE
DECLARE @Yield DATE
DECLARE @WebPubCo DATE
DECLARE @WebTenant DATE

--Sanity Checks
SELECT @AuditDate = CAST(PropertyValue AS DATE) FROM Configuration WHERE PropertyName = 'AuditDate'
SELECT @Calls = CAST(MAX(dbo.PeriodCacheCalls.[Date]) AS DATE) FROM dbo.PeriodCacheCalls
SELECT @Cleaning = CAST(MAX(dbo.PeriodCacheCleaning.DispenseWeek) AS DATE) FROM dbo.PeriodCacheCleaning
SELECT @CleaningDispense = CAST(MAX(dbo.PeriodCacheCleaningDispense.[Date]) AS DATE) FROM dbo.PeriodCacheCleaningDispense
SELECT @Quality = CAST(MAX(dbo.PeriodCacheQuality.TradingDay) AS DATE) FROM dbo.PeriodCacheQuality
SELECT @Sales = CAST(MAX(dbo.PeriodCacheSales.SaleDay) AS DATE) FROM dbo.PeriodCacheSales
SELECT @Temperature = CAST(MAX(dbo.PeriodCacheTemperature.[Date]) AS DATE) FROM dbo.PeriodCacheTemperature
SELECT @TradingDispense = CAST(MAX(dbo.PeriodCacheTradingDispense.TradingDay) AS DATE) FROM dbo.PeriodCacheTradingDispense
SELECT @Variance = CAST(MAX(dbo.PeriodCacheVariance.WeekCommencing) AS DATE) FROM dbo.PeriodCacheVariance
SELECT @Yield = CAST(MAX(dbo.PeriodCacheYield.DispenseDay) AS DATE) FROM dbo.PeriodCacheYield
SELECT @WebPubCo = CAST(MAX(WeekCommencing) AS DATE) FROM dbo.WebSiteUserAnalysisPubCo
SELECT @WebTenant = CAST(MAX(WeekCommencing) AS DATE) FROM dbo.WebSiteUserAnalysisTenant


SELECT	DB_NAME() AS [Database Name],
		@AuditDate AS [Audit Date], 
		@Calls AS [Calls Cache], 
		@Cleaning AS [Cleaning Cache], 
		@CleaningDispense AS [Cleaning Dispense Cache], 
		@Quality AS [Quality Cache], 
		@Sales AS [Sales Cache], 
		@Temperature AS [Temperature Cache], 
		@TradingDispense AS [Trading Dispense Cache], 
		@Variance AS [Variance Cache], 
		@Yield AS [Yield Cache],
		@WebPubCo AS [PubCo Web Cache],
		@WebTenant AS [Tenant Web Cache]