---------------------------------------------------------------------------
--
--  Function Header
--
---------------------------------------------------------------------------
CREATE FUNCTION fnTimePart
(
	@Date	DATETIME
)

RETURNS DATETIME

AS

BEGIN
	DECLARE @LocalDate	DATETIME
	
	SET @LocalDate = CAST(CONVERT(CHAR(8), @Date, 14) AS DATETIME)

	RETURN @LocalDate

END

