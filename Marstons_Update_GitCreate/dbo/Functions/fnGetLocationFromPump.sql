
CREATE FUNCTION [dbo].[fnGetLocationFromPump]
(
	@EDISID 	INTEGER,
	@Pump 	INTEGER,
	@Date 		DATETIME
)

RETURNS INT

AS

BEGIN
	DECLARE @Location	INTEGER

	SELECT TOP 1 @Location = LocationID
	FROM PumpSetup
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidFrom <= @Date AND (ValidTo >= @Date OR ValidTo IS NULL)
	ORDER BY ValidFrom DESC


	
	RETURN @Location

END




