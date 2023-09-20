---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddProductPrice
(
	@EDISID		INT,
	@ProductID	INT,
	@Price		MONEY
)

AS

DECLARE @Today			DATETIME
DECLARE @PreviousValidFrom	DATETIME

SET DATEFORMAT ymd

SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)

SELECT @PreviousValidFrom = ValidFrom
FROM dbo.ProductPrices
WHERE EDISID = @EDISID
AND ProductID = @ProductID
AND ValidTo IS NULL

IF @PreviousValidFrom IS NOT NULL
BEGIN
	IF @PreviousValidFrom >= @Today
		DELETE FROM dbo.ProductPrices
		WHERE EDISID = @EDISID
		AND ProductID = @ProductID
		AND ValidTo IS NULL
	ELSE
		UPDATE dbo.ProductPrices
		SET ValidTo = DATEADD(d, -1, @Today)
		WHERE EDISID = @EDISID
		AND ProductID = @ProductID
		AND ValidTo IS NULL
	
END

INSERT INTO dbo.ProductPrices
(EDISID, ProductID, Price, ValidFrom, ValidTo)
VALUES
(@EDISID, @ProductID, @Price, @Today, NULL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProductPrice] TO PUBLIC
    AS [dbo];

