CREATE PROCEDURE [dbo].[BackdateFontSetup]
(
	@EDISID	INT,
	@Pump		INT,
	@ProductID	INT,
	@StartDate	DATETIME,
	@EndDate	DATETIME
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID		INTEGER
DECLARE @GlobalProductID		INTEGER
DECLARE @IsNewProductMetric	BIT
DECLARE @IsOldProductMetric		BIT
DECLARE @Location		INTEGER

SELECT @IsNewProductMetric = IsMetric
FROM Products
WHERE [ID] = @ProductID

SELECT @IsOldProductMetric = IsMetric, @Location = LocationID
FROM PumpSetup
JOIN Products ON Products.[ID] = PumpSetup.ProductID
JOIN Locations ON LocationID = Locations.ID
WHERE PumpSetup.EDISID = @EDISID
AND PumpSetup.Pump = @Pump
AND (PumpSetup.ValidFrom <= @EndDate)
AND (ISNULL(PumpSetup.ValidTo, @EndDate) >= @StartDate)

--Check if product metric types are different
IF @IsOldProductMetric <> @IsNewProductMetric
BEGIN
	--Store old value in PintsBackup column
	UPDATE dbo.DispenseActions
	SET PintsBackup = Pints
	FROM dbo.DispenseActions
	WHERE DispenseActions.EDISID = @EDISID
	AND DATEADD(dd, 0, DATEDIFF(dd, 0, DispenseActions.StartTime)) BETWEEN @StartDate AND @EndDate
	AND DispenseActions.Pump = @Pump
	AND DispenseActions.PintsBackup = 0

	--Update the product and Pints value if new product is not metric
	UPDATE dbo.DispenseActions
	SET dbo.DispenseActions.Product = @ProductID, Pints = (Pints*5)/1.75975326/10, Location = @Location
	FROM dbo.DispenseActions
	WHERE (@IsOldProductMetric = 1 AND @IsNewProductMetric = 0)
	AND DispenseActions.EDISID = @EDISID
	AND DATEADD(dd, 0, DATEDIFF(dd, 0, DispenseActions.StartTime)) BETWEEN @StartDate AND @EndDate
	AND DispenseActions.Pump = @Pump

	--Do the same for DLData
	UPDATE dbo.DLData
	SET dbo.DLData.Product = @ProductID, Quantity = (Quantity*5)/1.75975326/10
	FROM dbo.DLData
	JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
	WHERE (@IsOldProductMetric = 1 AND @IsNewProductMetric = 0)
	AND MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	AND DLData.Pump = @Pump

	--Update the product and Pints value if new product is metric
	UPDATE dbo.DispenseActions
	SET dbo.DispenseActions.Product = @ProductID, Pints = (Pints/5)*1.75975326*10, Location = @Location
	FROM dbo.DispenseActions
	WHERE (@IsOldProductMetric = 0 AND @IsNewProductMetric = 1)
	AND DispenseActions.EDISID = @EDISID
	AND DATEADD(dd, 0, DATEDIFF(dd, 0, DispenseActions.StartTime)) BETWEEN @StartDate AND @EndDate
	AND DispenseActions.Pump = @Pump

	--Do the same for DLData
	UPDATE dbo.DLData
	SET dbo.DLData.Product = @ProductID, Quantity = (Quantity/5)*1.75975326*10
	FROM dbo.DLData
	JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
	WHERE (@IsOldProductMetric = 0 AND @IsNewProductMetric = 1)
	AND MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	AND DLData.Pump = @Pump

END
ELSE
BEGIN
	--No difference in product metric values, so simply update product (and location) in DispenseConditions and DLData
	UPDATE dbo.DLData
	SET dbo.DLData.Product = @ProductID
	FROM dbo.DLData
	JOIN dbo.MasterDates
	ON MasterDates.[ID] = DLData.DownloadID
	WHERE MasterDates.EDISID = @EDISID
	AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
	AND DLData.Pump = @Pump

	UPDATE dbo.DispenseActions
	SET dbo.DispenseActions.Product = @ProductID, Location = @Location
	FROM dbo.DispenseActions
	WHERE DispenseActions.EDISID = @EDISID
	AND DATEADD(dd, 0, DATEDIFF(dd, 0, DispenseActions.StartTime)) BETWEEN @StartDate AND @EndDate
	AND DispenseActions.Pump = @Pump

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[BackdateFontSetup] TO PUBLIC
    AS [dbo];

