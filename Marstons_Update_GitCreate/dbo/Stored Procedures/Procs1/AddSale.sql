CREATE PROCEDURE [dbo].[AddSale]
(
	@EDISID 	INTEGER, 
	@Date		DATETIME,
	@ProductID	INTEGER = NULL,
	@Quantity	FLOAT,
	@SaleIdent	VARCHAR(255),
	@SaleTime	DATETIME,
	@ID		INT 			OUTPUT,
	@ProductAlias	VARCHAR(50) = NULL,
	@External	BIT = 0,
	@SiteID		VARCHAR(50) = NULL
)

AS

SET NOCOUNT ON

DECLARE @MasterDateID	INTEGER
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER
DECLARE @TradingDate	DATETIME

-- Ensure Date only contains date (not time)
SET @Date = CAST(CONVERT(VARCHAR(10), @Date, 12) AS DATETIME)

-- Ensure SaleTime only contains time (not date)
SET @SaleTime = CAST('1899-12-30 ' + CONVERT(VARCHAR(10), CAST(@SaleTime AS DATETIME), 8) AS DATETIME)

-- Calculate TradingDate for storage (faster than recalculating on every read query!)
SET @TradingDate = CASE WHEN DATEPART(Hour, @SaleTime) < 5 THEN DATEADD(Day, -1, @Date) ELSE @Date END

-- Lookups below for EPOS Import Service, where EDISID and ProductID is not known
IF @SiteID IS NOT NULL
BEGIN
	SELECT @EDISID = EDISID
	FROM dbo.Sites
	WHERE SiteID = @SiteID
END

IF @ProductID IS NULL
BEGIN
	SELECT @ProductID = ProductID
	FROM dbo.ProductAlias
	WHERE UPPER(Alias) = UPPER(@ProductAlias)
END

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
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @ProductID 

	EXEC [SQL2\SQL2].[Global].dbo.AddSale @GlobalEDISID, @Date, @GlobalProductID, @Quantity, @SaleIdent, @SaleTime, @ID, @ProductAlias, @External
END
*/

INSERT INTO dbo.Sales
(MasterDateID, ProductID, Quantity, SaleIdent, SaleTime, EDISID, ProductAlias, [External], TradingDate, SaleDate)
VALUES
(@MasterDateID, @ProductID, @Quantity, @SaleIdent, @SaleTime, @EDISID, @ProductAlias, @External, @TradingDate, @Date)

SET @ID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSale] TO PUBLIC
    AS [dbo];

