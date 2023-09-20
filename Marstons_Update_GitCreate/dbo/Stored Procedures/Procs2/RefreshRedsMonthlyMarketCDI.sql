CREATE PROCEDURE dbo.RefreshRedsMonthlyMarketCDI
(
	@FromMonday		DATETIME,
	@ToMonday		DATETIME,
	@MarketCDI		FLOAT
)
AS

SET NOCOUNT ON
SET DATEFIRST 1

DELETE
FROM dbo.RedsMonthlyCDI
WHERE DatabaseID = 0
AND FromMonday = @FromMonday
AND ToMonday = @ToMonday
			
INSERT INTO dbo.RedsMonthlyCDI
(DatabaseID, MonthNumber, [Month], [Year], FromMonday, ToMonday, CDI)
SELECT	0,
		MONTH(@ToMonday),
		CASE MONTH(@ToMonday)	WHEN 1 THEN 'January'
										WHEN 2 THEN 'February'
										WHEN 3 THEN 'March'
										WHEN 4 THEN 'April'
										WHEN 5 THEN 'May'
										WHEN 6 THEN 'June'
										WHEN 7 THEN 'July'
										WHEN 8 THEN 'August'
										WHEN 9 THEN 'September'
										WHEN 10 THEN 'October'
										WHEN 11 THEN 'November'
										WHEN 12 THEN 'December' END,
		YEAR(@ToMonday),
		@FromMonday,
		@ToMonday,
		@MarketCDI

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RefreshRedsMonthlyMarketCDI] TO PUBLIC
    AS [dbo];

