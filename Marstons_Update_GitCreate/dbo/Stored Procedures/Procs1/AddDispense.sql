CREATE PROCEDURE [dbo].[AddDispense]
(
	@EDISID 	INTEGER, 
	@Date		DATETIME,
	@Pump	INTEGER,
	@Shift		INTEGER,
	@Product	INTEGER = NULL,
	@Quantity	REAL
)

AS

BEGIN TRANSACTION

SET NOCOUNT ON

DECLARE @DownloadID	INTEGER
DECLARE @ExistingWater	INTEGER
DECLARE @ProductIsMetric	BIT
DECLARE @Pints		REAL
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProduct	INTEGER

-- Find MasterDate, adding it if we need to
SELECT @DownloadID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @DownloadID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @DownloadID = @@IDENTITY
END

-- Find historical product if we need to
IF @Product IS NULL
BEGIN
	SELECT @Product = ProductID, @ProductIsMetric = IsMetric
	FROM dbo.PumpSetup
	JOIN dbo.Products ON dbo.Products.ID = dbo.PumpSetup.ProductID
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidFrom <= @Date
	AND (ValidTo >= @Date OR ValidTo IS NULL)

	IF @Product IS NULL
	BEGIN
		SELECT @Product = ID, @ProductIsMetric = IsMetric
		FROM dbo.Products
		WHERE [Description] = '0'
	END

	IF @ProductIsMetric = 1
	BEGIN
		SET @Pints = (@Quantity / 5.0) * 1.75975326
	END
	ELSE
	BEGIN
		SET @Pints = @Quantity
	END
END
ELSE
BEGIN
	SET @Pints = @Quantity
END

-- Delete water in same site/day/shift, since it has probably been auto-cleaned
SELECT @ExistingWater = COUNT(*)
FROM dbo.WaterStack
WHERE WaterID = @DownloadID
AND DATEPART(hh, [Time]) = @Shift-1
AND Line =@Pump

IF @ExistingWater > 0
BEGIN
	DELETE FROM dbo.WaterStack
	WHERE WaterID = @DownloadID
	AND DATEPART(hh, [Time]) = @Shift-1
	AND Line =@Pump
END

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProduct = GlobalID
	FROM Products
	WHERE [ID] = @Product

	EXEC [SQL2\SQL2].[Global].dbo.AddDispense @GlobalEDISID, @Date, @Pump, @Shift, @GlobalProduct, @Quantity
END
*/

SET NOCOUNT OFF

INSERT INTO dbo.DLData
(DownloadID, Pump, Shift, Product, Quantity)
VALUES
(@DownloadID, @Pump, @Shift, @Product, @Pints)

/*
-- Minor night-time dispenses go into waterstack instead
IF (@Pints <= 0.5) AND (@Shift BETWEEN 2 AND 11)
BEGIN
	INSERT INTO dbo.WaterStack
	(WaterID, Time, Line, Volume)
	VALUES
	(@DownloadID, CAST('1899-12-30 ' + CAST(@Shift-1 AS VARCHAR) +':00:00.000' AS DATETIME), @Pump, @Pints)
END
ELSE
BEGIN
	INSERT INTO dbo.DLData
	(DownloadID, Pump, Shift, Product, Quantity)
	VALUES
	(@DownloadID, @Pump, @Shift, @Product, @Pints)
END
*/

COMMIT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDispense] TO PUBLIC
    AS [dbo];

