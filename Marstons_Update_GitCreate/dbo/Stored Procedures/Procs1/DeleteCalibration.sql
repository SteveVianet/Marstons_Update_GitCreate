---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE DeleteCalibration
(
	@EDISID			INT,
	@Pump			INT
)

AS

DECLARE @Today		DATETIME
DECLARE @PreviousValidFrom	DATETIME

SET DATEFORMAT ymd

SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)

SELECT @PreviousValidFrom = ValidFrom
FROM dbo.Calibrations
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

IF @PreviousValidFrom IS NOT NULL
BEGIN
	IF @PreviousValidFrom >= @Today
		DELETE FROM dbo.Calibrations
		WHERE EDISID = @EDISID
		AND Pump = @Pump
		AND ValidTo IS NULL
	ELSE
		UPDATE dbo.Calibrations
		SET ValidTo = DATEADD(d, -1, @Today)
		WHERE ValidTo IS NULL
		AND EDISID = @EDISID
		AND Pump = @Pump
	
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCalibration] TO PUBLIC
    AS [dbo];

