---------------------------------------------------------------------------
--
--  Function Header
--
---------------------------------------------------------------------------
CREATE FUNCTION fnGetMonday
(
	@Date	DATETIME
)

RETURNS DATETIME

AS

BEGIN
	DECLARE @LocalDate	DATETIME

	IF @Date IS NULL
		RETURN NULL

	SET @LocalDate = @Date

	WHILE DATEPART(dw, @LocalDate) <> 1
	BEGIN
		SET @LocalDate = DATEADD(d, -1, @LocalDate)
	END

	RETURN @LocalDate

END


