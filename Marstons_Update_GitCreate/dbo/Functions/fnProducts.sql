CREATE FUNCTION dbo.fnProducts
(
	@StartDate	DATETIME, 
	@EndDate	DATETIME,
	@EDISID		INT
)

RETURNS @Products TABLE (Product INT)

AS

BEGIN
	INSERT INTO @Products
	SELECT Product
	FROM dbo.DLData
	JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
	WHERE MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	AND MasterDates.EDISID = @EDISID
	GROUP BY Product

	UNION

	SELECT Product
	FROM dbo.Delivery
	JOIN dbo.MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
	WHERE MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	AND MasterDates.EDISID = @EDISID
	GROUP BY Product

	RETURN 
END


