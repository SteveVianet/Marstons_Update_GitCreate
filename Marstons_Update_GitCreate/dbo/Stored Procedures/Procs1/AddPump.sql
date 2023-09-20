CREATE PROCEDURE [dbo].[AddPump]
(
	@EDISID		INT,
	@Pump		INT,
	@ProductID	INT,
	@LocationID	INT,
	@InUse		BIT = 1,
	@BarPosition	INT = 0,
	@ValidFrom	DATETIME = NULL,
	@ValidTo	DATETIME = NULL
)

AS

IF (@ValidFrom IS NOT NULL)
BEGIN
	INSERT INTO dbo.PumpSetup
		(EDISID, Pump, ProductID, LocationID, ValidFrom, ValidTo, InUse, BarPosition)
	VALUES
		(@EDISID, @Pump, @ProductID, @LocationID, @ValidFrom, @ValidTo, @InUse, @BarPosition)
END

ELSE

BEGIN
	DECLARE @Today		DATETIME
	DECLARE @PreviousValidFrom	DATETIME

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

	INSERT INTO dbo.PumpSetup
	(EDISID, Pump, ProductID, LocationID, ValidFrom, ValidTo, InUse, BarPosition)
	VALUES
	(@EDISID, @Pump, @ProductID, @LocationID, @Today, NULL, @InUse, @BarPosition)


	COMMIT
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPump] TO PUBLIC
    AS [dbo];

