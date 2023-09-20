CREATE PROCEDURE SetPumpPosition
(
	@EDISID	INTEGER,
	@Pump		INTEGER,
	@BarPosition	INTEGER
)

AS

DECLARE @GlobalEDISID	INTEGER

SET NOCOUNT ON

UPDATE dbo.PumpSetup
SET BarPosition = @BarPosition
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.SetPumpPosition @GlobalEDISID, @Pump, @BarPosition
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetPumpPosition] TO PUBLIC
    AS [dbo];

