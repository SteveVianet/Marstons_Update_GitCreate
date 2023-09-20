﻿CREATE PROCEDURE [dbo].[DeletePump]
(
	@EDISID	INT,
	@Pump		INT
)

AS

DECLARE @Today		SMALLDATETIME
DECLARE @PreviousValidFrom	SMALLDATETIME
DECLARE @GlobalEDISID	INTEGER

SET XACT_ABORT ON

BEGIN TRAN

SET DATEFORMAT ymd

SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)

SELECT @PreviousValidFrom = ValidFrom
FROM dbo.PumpSetup
WHERE Pump = @Pump
AND EDISID = @EDISID
AND ValidTo IS NULL

IF @PreviousValidFrom IS NOT NULL
BEGIN
	IF @PreviousValidFrom >= @Today
		DELETE FROM dbo.PumpSetup
		WHERE Pump = @Pump
		AND EDISID = @EDISID
		AND ValidTo IS NULL
	ELSE
		UPDATE dbo.PumpSetup
		SET ValidTo = DATEADD(d, -1, @Today)
		WHERE ValidTo IS NULL
		AND Pump = @Pump
		AND EDISID = @EDISID
	
END

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeletePump @GlobalEDISID, @Pump
END
*/

COMMIT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeletePump] TO PUBLIC
    AS [dbo];

