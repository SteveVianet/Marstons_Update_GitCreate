CREATE PROCEDURE [dbo].[DeleteSalesBySchedule]
(
	@ScheduleID	INT,
	@DateFrom	DATETIME,
	@DateTo		DATETIME
)

AS

DELETE Sales FROM Sales
JOIN dbo.MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = dbo.MasterDates.EDISID
WHERE dbo.ScheduleSites.ScheduleID = @ScheduleID
AND MasterDates.[Date] BETWEEN @DateFrom AND @DateTo
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSalesBySchedule] TO PUBLIC
    AS [dbo];

