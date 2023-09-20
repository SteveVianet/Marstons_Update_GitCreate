---------------------------------------------------------------------------
--
--  Function Header
--
---------------------------------------------------------------------------
CREATE FUNCTION fnDeliveryVarianceDelivered
(
	@StartDate 	DATETIME, 
	@EndDate 	DATETIME,
	@EDISID		INT
)

RETURNS TABLE 

AS

RETURN
(
	SELECT	Products.[ID] AS Product,
			dbo.fnGetMonday(MasterDates.[Date]) AS [Date],
			SUM(Delivery.Quantity) * 4.546 / 0.568 AS Quantity
	FROM Delivery
	JOIN Products
		ON Products.[ID] = Delivery.Product
	JOIN MasterDates
		ON MasterDates.[ID] = Delivery.DeliveryID
	WHERE	MasterDates.EDISID = @EDISID
	AND 		MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	GROUP BY	Products.[ID], 
			dbo.fnGetMonday(MasterDates.[Date])
)

