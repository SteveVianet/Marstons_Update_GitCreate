CREATE PROCEDURE [art].[GetTradingDispense]
(
	@From		DATE,
	@To			DATE
)

AS

--DECLARE @From	DATE = '2014-02-03'
--DECLARE @To	DATE = '2014-03-01'

-- Trading Day hardcoded to being at 5am for BMS/iDraught
DECLARE @TradingDayBeginsAt INT = 5

SELECT
	[Sites].[SiteID],
	[Sites].[Name],
	[Sites].[PostCode],
	DATEADD(HOUR, 
			[DLData].[Shift]-1, 
			CASE
				WHEN [DLData].[Shift]-1 < @TradingDayBeginsAt
				THEN DATEADD(DAY, -1, [MasterDates].[Date])
				ELSE [MasterDates].[Date]
			END) AS [TradingDateTime],
	SUM([DLData].[Quantity]) AS [Volume],
	'BMS' AS [LiquidType]
FROM [dbo].[Sites]
JOIN [dbo].[MasterDates] 
	ON [MasterDates].[EDISID] = [Sites].[EDISID]
JOIN [dbo].[DLData] 
	ON [DLData].[DownloadID] = [MasterDates].[ID]
JOIN [dbo].[Products]
	ON [Products].[ID] = [DLData].[Product]
WHERE 
	[Sites].[Hidden] = 0
AND [Sites].[SiteClosed] = 0
AND [Sites].[Quality] = 0
AND [Products].[Tied] = 1
AND [MasterDates].[Date] BETWEEN @From AND @To
GROUP BY
	[Sites].[SiteID],
	[Sites].[Name],
	[Sites].[PostCode],
	DATEADD(HOUR, 
			[DLData].[Shift]-1, 
			CASE
				WHEN [DLData].[Shift]-1 < @TradingDayBeginsAt
				THEN DATEADD(DAY, -1, [MasterDates].[Date])
				ELSE [MasterDates].[Date]
			END)
UNION

SELECT 
	[Sites].[SiteID],
	[Sites].[Name],
	[Sites].[PostCode],
	DATEADD(HOUR, 
			DATEPART(HOUR, [DispenseActions].[StartTime]),
			[DispenseActions].[TradingDay]) AS [TradingDateTime],
	SUM([DispenseActions].[Pints]) AS [Volume],
	[LiquidTypes].[Description] AS [LiquidType]
FROM [dbo].[Sites]
JOIN [dbo].[DispenseActions]
	ON [DispenseActions].[EDISID] = [Sites].[EDISID]
JOIN [dbo].[Products]
	ON [Products].[ID] = [DispenseActions].[Product]
JOIN [dbo].[LiquidTypes]
	ON [LiquidTypes].[ID] = [DispenseActions].[LiquidType]
WHERE 
	[Sites].[Hidden] = 0
AND [Sites].[SiteClosed] = 0
AND [Sites].[Quality] = 1
AND CAST([DispenseActions].[StartTime] AS DATE) BETWEEN @From AND @To
AND [DispenseActions].[LiquidType] = 2 --Beer
GROUP BY
	[Sites].[SiteID],
	[Sites].[Name],
	[Sites].[PostCode],
	DATEADD(HOUR, 
			DATEPART(HOUR, [DispenseActions].[StartTime]),
			[DispenseActions].[TradingDay]),
	[LiquidTypes].[Description]

--ORDER BY 
--	[SiteID],
--	[TradingDateTime]


GO
GRANT EXECUTE
    ON OBJECT::[art].[GetTradingDispense] TO PUBLIC
    AS [dbo];

