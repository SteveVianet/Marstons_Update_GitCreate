---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteProductPrice
(
	@EDISID		INT,
	@ProductID	INT
)

AS

DECLARE @Today		DATETIME
DECLARE @PreviousValidFrom	DATETIME

SET DATEFORMAT ymd

SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)

SELECT @PreviousValidFrom = ValidFrom
FROM dbo.ProductPrices
WHERE ProductID = @ProductID
AND EDISID = @EDISID
AND ValidTo IS NULL

IF @PreviousValidFrom IS NOT NULL
BEGIN
	IF @PreviousValidFrom >= @Today
		DELETE FROM dbo.ProductPrices
		WHERE ProductID = @ProductID
		AND EDISID = @EDISID
		AND ValidTo IS NULL
	ELSE
		UPDATE dbo.ProductPrices
		SET ValidTo = DATEADD(d, -1, @Today)
		WHERE ValidTo IS NULL
		AND ProductID = @ProductID
		AND EDISID = @EDISID
	
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteProductPrice] TO PUBLIC
    AS [dbo];

