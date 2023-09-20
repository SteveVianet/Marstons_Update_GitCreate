
CREATE FUNCTION [dbo].[GetSitePumpIsKeg]
(
	@EDISID 	INTEGER,
	@Pump 		INTEGER,
	@Date 		DATETIME
)

RETURNS BIT

AS

BEGIN
	DECLARE @IsKeg	BIT

	SELECT TOP 1 @IsKeg = CASE WHEN IsCask = 0 AND IsWater = 0 AND IsMetric = 0 THEN 1 ELSE 0 END
	FROM PumpSetup
	JOIN Products ON Products.ID = PumpSetup.ProductID
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidFrom <= @Date AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND Products.IsWater = 0
	AND Products.IsMetric = 0
	ORDER BY ValidFrom DESC
	
	RETURN @IsKeg

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePumpIsKeg] TO PUBLIC
    AS [dbo];

