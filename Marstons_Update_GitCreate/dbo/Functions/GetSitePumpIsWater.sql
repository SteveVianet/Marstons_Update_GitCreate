

CREATE FUNCTION [dbo].[GetSitePumpIsWater]
(
	@EDISID 	INTEGER,
	@Pump 		INTEGER,
	@Date 		DATETIME
)

RETURNS BIT

AS

BEGIN
	DECLARE @IsWater	BIT

	SET @IsWater = 0

	SELECT TOP 1 @IsWater = IsWater
	FROM PumpSetup
	JOIN Products ON Products.ID = PumpSetup.ProductID
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidFrom <= @Date AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND Products.IsWater = 1
	ORDER BY ValidFrom DESC
	
	RETURN @IsWater

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePumpIsWater] TO PUBLIC
    AS [dbo];

