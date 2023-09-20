CREATE PROCEDURE [dbo].[GetWebCDConfiguration]
AS

SET NOCOUNT ON

DECLARE @CurrentPeriod VARCHAR(50)
DECLARE @PeriodFrom DATETIME
DECLARE @PeriodTo DATETIME
DECLARE @CDCashValue FLOAT
DECLARE @HighCDValue FLOAT

SELECT TOP 1 @CurrentPeriod = Period, @PeriodFrom = FromWC, @PeriodTo = DATEADD(DAY, 6, ToWC)
FROM dbo.PubcoCalendars
WHERE Processed = 1
ORDER BY FromWC DESC

SELECT @CDCashValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit Cash Value'

SELECT @HighCDValue = CAST(PropertyValue AS FLOAT)
FROM dbo.Configuration
WHERE PropertyName = 'Calculated Deficit High CD Threshold'

SELECT	@CurrentPeriod AS CurrentPeriod,
		@PeriodFrom AS PeriodFrom,
		@PeriodTo AS PeriodTo,
		ISNULL(@CDCashValue, 0) AS CDCashValue,
		ISNULL(@HighCDValue, 0) AS HighCDValue

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebCDConfiguration] TO PUBLIC
    AS [dbo];

