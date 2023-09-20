CREATE PROCEDURE [dbo].[RemovePumpSetup]
(
	@EDISID INT,
	@Pump INT,
	@ProductID INT,
	@LocationID INT,
	@ValidFrom Date,
	@ValidTo Date = NULL,
	@InUse BIT
)

AS

BEGIN
	DECLARE @PreviousValidFrom DATETIME
	DECLARE @Today DATETIME 

	SET @Today = CAST(CONVERT(VARCHAR(10), GETDATE(), 20) AS SMALLDATETIME)

	SELECT @PreviousValidFrom = ValidFrom
	FROM PumpSetup
	WHERE Pump = @Pump
	AND EDISID = @EDISID
	AND ValidTo IS NULL

	IF @PreviousValidFrom IS NOT NULL
	BEGIN
		IF @PreviousValidFrom >= @Today
		BEGIN
			DELETE FROM PumpSetup
			WHERE Pump = @Pump
			AND EDISID = @EDISID
			AND ValidTo IS NULL
		END
		ELSE
		BEGIN
		UPDATE PumpSetup
			SET	ProductID = @ProductID,
			LocationID = @LocationID,
			ValidFrom = @ValidFrom,
			ValidTo = @ValidTo,
			InUse = @InUse
			WHERE EDISID = @EDISID and Pump = @Pump AND ValidFrom = (SELECT MAX(ValidFrom) FROM PumpSetup WHERE EDISID = @EDISID and Pump = @Pump)
		END
	END

	IF @PreviousValidFrom IS NULL
		BEGIN
			UPDATE PumpSetup
			SET	ProductID = @ProductID,
			LocationID = @LocationID,
			ValidFrom = @ValidFrom,
			ValidTo = @ValidTo,
			InUse = @InUse
			WHERE EDISID = @EDISID and Pump = @Pump AND ValidFrom = (SELECT MAX(ValidFrom) FROM PumpSetup WHERE EDISID = @EDISID and Pump = @Pump)
		END
	
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RemovePumpSetup] TO PUBLIC
    AS [dbo];

