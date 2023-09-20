
CREATE PROCEDURE dbo.DeleteSiteDispenseActionsByShift
(
	@EDISID				INT,
	@DispenseDate		DATETIME,
	@Pump				INT,
	@Shift				INT
)
AS

--Note: This procedure does not support site groups as it will be called by the Line Cleaning Service & related software
--Note: DispenseDate is actual date, not trading date

SET NOCOUNT ON

DELETE FROM DispenseActions
WHERE EDISID = @EDISID
AND CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, StartTime))) = @DispenseDate
AND Pump = @Pump
AND DATEPART(HOUR, StartTime) = @Shift-1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteSiteDispenseActionsByShift] TO PUBLIC
    AS [dbo];

