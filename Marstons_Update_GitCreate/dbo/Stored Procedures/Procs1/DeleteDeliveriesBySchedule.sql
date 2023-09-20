---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[DeleteDeliveriesBySchedule]
(
	@ScheduleID	INT,
	@DateFrom	DATETIME,
	@DateTo		DATETIME
)

AS

DELETE Delivery FROM dbo.Delivery 
JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN dbo.ScheduleSites ON ScheduleSites.EDISID = dbo.MasterDates.EDISID
WHERE dbo.ScheduleSites.ScheduleID = @ScheduleID
AND MasterDates.[Date] BETWEEN @DateFrom AND @DateTo
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDeliveriesBySchedule] TO PUBLIC
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDeliveriesBySchedule] TO [TeamLeader]
    AS [dbo];

