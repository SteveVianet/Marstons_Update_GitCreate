---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetHistoricalProduct
(
	@EDISID			INTEGER,
	@Pump			INTEGER,
	@Date			DATETIME,
	@HistoricalProduct	INTEGER OUTPUT
)

AS

DECLARE @Product	INTEGER

SELECT @Product = ProductID
FROM dbo.PumpSetup
WHERE Pump = @Pump
AND EDISID = @EDISID
AND ValidFrom <= @Date
AND (ValidTo >= @Date OR ValidTo IS NULL)

IF @Product IS NULL
	SET @Product = -1

SET @HistoricalProduct = @Product


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetHistoricalProduct] TO PUBLIC
    AS [dbo];

