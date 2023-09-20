---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetMeters

AS

SELECT [ID],
	EDISID,
	DigitID,
	TextID,
	ModemSerial,
	IMEI,
	FirmwareVersion
FROM dbo.Meters


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMeters] TO PUBLIC
    AS [dbo];

