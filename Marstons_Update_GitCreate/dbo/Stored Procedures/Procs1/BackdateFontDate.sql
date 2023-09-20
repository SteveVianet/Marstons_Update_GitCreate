CREATE PROCEDURE dbo.BackdateFontDate
(
	@EDISID		INT,
	@Pump		INT,
	@NewDate	DATETIME
)

AS

DECLARE @PumpCount		INT
DECLARE @CurrentPumpDate	DATETIME
DECLARE @ValidFrom		DATETIME
DECLARE @ValidTo		DATETIME
DECLARE @Debug		VARCHAR(1024)
DECLARE @GlobalEDISID	INTEGER

SET NOCOUNT ON

-- Nasty debug thingy
SET @Debug = 'EDISID = ' + CAST(@EDISID AS VARCHAR) + ', Pump = ' + CAST(@Pump AS VARCHAR) + ', Date = ' + CONVERT(VARCHAR, @NewDate, 103)
EXEC dbo.LogError 249, @Debug, 'dbo.BackdateFontDate', 'Begin'

-- Get number of current rows for specified site/pump
SELECT @PumpCount = COUNT(*)
FROM dbo.PumpSetup
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

-- Ensure pump actually exists
IF @PumpCount <> 1
BEGIN
	RAISERROR ('Pump not found', 16, 1)
	RETURN -1
END

-- Get date of current pump
SELECT @CurrentPumpDate = ValidFrom
FROM dbo.PumpSetup
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo IS NULL

-- Ensure current date occurs after the new date
IF @CurrentPumpDate < @NewDate
BEGIN
	RAISERROR ('Date occurs after the current ValidFrom date', 16, 1)
	RETURN -1
END

-- Get number of previous pumps
SELECT @PumpCount = COUNT(*)
FROM dbo.PumpSetup
WHERE EDISID = @EDISID
AND Pump = @Pump
AND ValidTo < @CurrentPumpDate

SET @Debug = 'PumpCount = ' + CAST(@PumpCount AS VARCHAR) + ', CurrentPumpDate = ' + CAST(@CurrentPumpDate AS VARCHAR) + ', ValidFrom = ' + CONVERT(VARCHAR, @ValidFrom, 103) + ', ValidTo = ' + CONVERT(VARCHAR, @ValidTo, 103)
EXEC dbo.LogError 249, @Debug, 'dbo.BackdateFontDate', 'Before update'

-- If we have previous pumps, do updates/deletes
IF @PumpCount > 0
BEGIN
	-- Loop through each previous pump, updating or deleting on demand
	DECLARE PreviousPumps CURSOR LOCAL STATIC FOR
	SELECT ValidFrom, ValidTo
	FROM dbo.PumpSetup
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND NOT ValidTo IS NULL
	ORDER BY ValidFrom DESC
	
	OPEN PreviousPumps

	FETCH NEXT FROM PreviousPumps INTO @ValidFrom, @ValidTo

	WHILE (@@FETCH_STATUS = 0) AND (@ValidFrom >= @NewDate)
	BEGIN
		DELETE FROM dbo.PumpSetup
		WHERE EDISID = @EDISID
		AND Pump = @Pump
		AND ValidFrom = @ValidFrom
		AND ValidTo = @ValidTo

		FETCH NEXT FROM PreviousPumps INTO @ValidFrom, @ValidTo
	END
	
	IF (NOT @ValidFrom IS NULL) AND (@ValidTo >= @NewDate)
	BEGIN
		UPDATE dbo.PumpSetup
		SET ValidTo = DATEADD(d, -1, @NewDate)
		WHERE EDISID = @EDISID
		AND Pump = @Pump
		AND ValidFrom = @ValidFrom

	END
	
	UPDATE dbo.PumpSetup
	SET ValidFrom = @NewDate
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidTo IS NULL

	CLOSE PreviousPumps
	DEALLOCATE PreviousPumps

END
ELSE
BEGIN
	-- No previous pumps defined, just do an update
	UPDATE dbo.PumpSetup
	SET ValidFrom = @NewDate
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ValidTo IS NULL
END

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.BackdateFontDate @GlobalEDISID, @Pump, @NewDate
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[BackdateFontDate] TO PUBLIC
    AS [dbo];

