CREATE PROCEDURE [dbo].[AddWebSiteSale]
(
	@EDISID 		INTEGER, 
	@DateAndTime	DATETIME,
	@ProductID		INTEGER,
	@Quantity		FLOAT,
	@SaleIdent		VARCHAR(255),
	@ProductAlias		VARCHAR(50),
	@ID			INTEGER		OUT
)

AS

SET NOCOUNT ON

DECLARE @Date		DATETIME
DECLARE @SaleTime		DATETIME
DECLARE @TradingDate	DATETIME
DECLARE @MasterDateID	INTEGER
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER
DECLARE @ExistingQuantity	FLOAT

-- Ensure Date only contains date (not time)
SET @Date = CAST(CONVERT(VARCHAR(10), @DateAndTime, 12) AS DATETIME)

-- Ensure SaleTime only contains time (not date)
SET @SaleTime = CAST('1899-12-30 ' + CONVERT(VARCHAR(10), CAST(@DateAndTime AS DATETIME), 8) AS DATETIME)

-- Calculate TradingDate for storage (faster than recalculating on every read query!)
SET @TradingDate = CASE WHEN DATEPART(Hour, @SaleTime) < 5 THEN DATEADD(Day, -1, @Date) ELSE @Date END

-- Find or add MasterDate
SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @MasterDateID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @MasterDateID = @@IDENTITY
END

/*
-- Horrible Global stuff
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID 

	EXEC [SQL2\SQL2].[Global].dbo.AddWebSiteSale @GlobalEDISID, @DateAndTime, @GlobalProductID, @Quantity, @SaleIdent, @ProductAlias, @ID OUT
END
*/


IF @Quantity = 0
BEGIN
	DELETE
	FROM dbo.Sales
	WHERE MasterDateID = @MasterDateID
	AND ProductID = @ProductID
	AND SaleTime = @SaleTime
END
ELSE
BEGIN
	SELECT @ExistingQuantity = Quantity, @ID = [ID]
	FROM dbo.Sales
	WHERE MasterDateID = @MasterDateID
	AND ProductID = @ProductID
	AND SaleTime = @SaleTime

	IF @ExistingQuantity > 0
	BEGIN
		UPDATE dbo.Sales
		SET Quantity = @Quantity
		WHERE MasterDateID = @MasterDateID
		AND ProductID = @ProductID
		AND SaleTime = @SaleTime

	END
	ELSE
	BEGIN
		INSERT INTO dbo.Sales
		(MasterDateID, ProductID, Quantity, SaleIdent, SaleTime, EDISID, ProductAlias, [External], TradingDate, SaleDate)
		VALUES
		(@MasterDateID, @ProductID, @Quantity, @SaleIdent, @SaleTime, @EDISID, @ProductAlias, 1, @TradingDate, @Date)

		SET @ID = @@IDENTITY
	END
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddWebSiteSale] TO PUBLIC
    AS [dbo];

