
CREATE FUNCTION [dbo].[GetSitePumpIsCask]
(
	@EDISID 	INTEGER,
	@Pump 		INTEGER,
	@Date 		DATETIME
)

RETURNS BIT

AS

BEGIN
	DECLARE @IsCask	BIT

	SELECT TOP 1 @IsCask = IsCask
	FROM PumpSetup
	JOIN Products ON Products.ID = PumpSetup.ProductID
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidFrom <= @Date AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND Products.IsWater = 0
	AND Products.IsMetric = 0
	ORDER BY ValidFrom DESC
	
	RETURN @IsCask

END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitePumpIsCask] TO PUBLIC
    AS [dbo];

