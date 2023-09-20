---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetCalibrations
(
	@EDISID		INT
)

AS

SELECT	[Pump],
	[LocationID],
	[ProductID],
	[FlowMeterTypeID],
	[ScalarValue1],
	[ScalarValue2],
	[ScalarValue3]
FROM dbo.Calibrations
WHERE EDISID = @EDISID
AND ValidTo IS NULL
ORDER BY Pump


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalibrations] TO PUBLIC
    AS [dbo];

