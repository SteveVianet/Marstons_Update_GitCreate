CREATE PROCEDURE [dbo].[GetGateway3WaterLineDispense]
(
	@EDISID	    INTEGER,
	@FromDate	DATE,
    @ToDate     DATE
)

AS

/* For Testing */
--DECLARE	@EDISID	    INTEGER = 538
--DECLARE	@FromDate	DATE    = '2016-05-23'
--DECLARE	@ToDate	    DATE    = '2016-05-28'

SELECT	WaterStack.[Line] AS [Pump],
        MasterDates.[Date],
		DATEPART(HOUR, WaterStack.[Time]) + 1 AS [Shift],
		WaterStack.[Volume],
		Products.[Description] AS [Product],
		Products.[ID] AS [ProductID],
        Products.[IsWater]
FROM dbo.WaterStack
JOIN dbo.MasterDates ON MasterDates.[ID] = WaterStack.[WaterID]
JOIN dbo.PumpSetup ON WaterStack.[Line] = PumpSetup.[Pump] AND PumpSetup.[EDISID] = MasterDates.[EDISID]
JOIN dbo.Products ON Products.[ID] = PumpSetup.[ProductID]
WHERE MasterDates.[Date] BETWEEN @FromDate AND @ToDate
AND MasterDates.EDISID = @EDISID
--AND Products.IsWater = 1
AND PumpSetup.ValidFrom <= @ToDate
AND (PumpSetup.ValidTo > @FromDate OR PumpSetup.ValidTo IS NULL)
--ORDER BY WaterStack.[Line], MasterDates.[Date], [Shift]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetGateway3WaterLineDispense] TO PUBLIC
    AS [dbo];

