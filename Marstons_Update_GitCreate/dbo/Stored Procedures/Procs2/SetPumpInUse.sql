CREATE PROCEDURE [dbo].[SetPumpInUse]
(
	@EDISID		INTEGER,
	@Pump		INTEGER,
	@InUse		BIT
)

AS

DECLARE @GlobalEDISID	INTEGER
DECLARE @ValidFrom DATE
DECLARE @ToDate DATE

SET NOCOUNT ON

UPDATE dbo.PumpSetup
SET InUse = @InUse
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

SELECT @ValidFrom = ValidFrom
FROM dbo.PumpSetup
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

--SET @ToDate = CAST(GETDATE() AS DATE)

--INSERT INTO QueuedSQL (SQLToExecute)
--SELECT 'EXEC [PeriodCacheCleaningStatusRebuild] ''' + CONVERT(VARCHAR, CAST(@ValidFrom AS DATE), 120) + ''', ''' +  CONVERT(VARCHAR, CAST(@ToDate AS DATE), 120) + ''', ' + CONVERT(VARCHAR, @EDISID)

/* Too Slow */
/* EXEC [PeriodCacheCleaningStatusRebuild] @ValidFrom, @ToDate, @EDISID */

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.SetPumpInUse @GlobalEDISID, @Pump, @InUse
END
*/

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetPumpInUse] TO PUBLIC
    AS [dbo];

