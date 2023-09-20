---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddCalibration
(
	@EDISID			INT,
	@Pump			INT,
	@LocationID		INT,
	@ProductID		INT,
	@FlowMeterTypeID	INT,
	@ScalarValue1		INT,
	@ScalarValue2		INT,
	@ScalarValue3		INT
)

AS

DECLARE @Today			DATETIME
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
		WHERE EDISID = @EDISID
		AND Pump = @Pump
		AND ValidTo IS NULL
	
END

INSERT INTO dbo.Calibrations
(EDISID, Pump, LocationID, ProductID, FlowMeterTypeID, ScalarValue1, ScalarValue2, ScalarValue3, ValidFrom, ValidTo)
VALUES
(@EDISID, @Pump, @LocationID, @ProductID, @FlowMeterTypeID, @ScalarValue1, @ScalarValue2, @ScalarValue3, @Today, NULL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCalibration] TO PUBLIC
    AS [dbo];

