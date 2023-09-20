CREATE PROCEDURE [dbo].[GetDeliveryDates]
(
	@EDISID	INTEGER,
	@From		DATETIME = NULL,
	@To		DATETIME = NULL	
)

AS


DECLARE @iEDISID AS INTEGER
DECLARE @iFrom AS DATETIME
DECLARE @iTo AS DATETIME

SET @iEDISID = @EDISID
SET @iFrom = @From
SET @iTo = @To


SELECT MD.[Date]
FROM (SELECT ID, EDISID, Date FROM MasterDates WHERE EDISID = @iEDISID) AS MD
JOIN dbo.Delivery
ON Delivery.DeliveryID = MD.[ID]
WHERE (MD.Date >= @iFrom OR @iFrom IS NULL) AND (MD.Date <= @iTo OR @iTo IS NULL)
GROUP BY MD.[Date]
ORDER BY MD.[Date]

--SELECT MasterDates.[Date]
--FROM dbo.MasterDates
--JOIN dbo.Delivery
--ON Delivery.DeliveryID = MasterDates.[ID]
--WHERE MasterDates.EDISID = @EDISID
--AND (MasterDates.Date >= @From OR @From IS NULL) AND (MasterDates.Date <= @To OR @To IS NULL)
--GROUP BY MasterDates.[Date]
--ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDeliveryDates] TO PUBLIC
    AS [dbo];

