CREATE PROCEDURE [dbo].[UpdatePumpSetup]
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

IF EXISTS (SELECT * FROM PumpSetup WHERE EDISID = @EDISID AND Pump = @Pump AND (ValidTo > @ValidFrom OR ValidTo IS NULL) AND (ValidFrom < @ValidFrom))
	BEGIN
		DECLARE @ExsisitngPumpSetup TABLE (
			EDISID INT,
			Pump INT,
			ProductID INT,
			LocationID INT,
			ValidFrom DATE,
			ValidTo DATE,
			InUse BIT,
			BarPosition INT
			)

		INSERT INTO @ExsisitngPumpSetup
			SELECT EDISID,Pump,ProductID, LocationID, ValidFrom, ValidTo, InUse, BarPosition
			FROM PumpSetup
			WHERE EDISID = @EDISID 
				AND Pump = @Pump 
				AND (ValidTo > @ValidFrom OR ValidTo IS NULL)
				AND (ValidFrom < @ValidFrom)

		DECLARE @ChangeExsistingValidTo DATE
		SET @ChangeExsistingValidTo = DATEADD(D,-1,@ValidFrom)

		UPDATE PumpSetup
		SET ValidTo = @ChangeExsistingValidTo
		WHERE EDISID = @EDISID AND Pump = @Pump AND (ValidTo > @ValidFrom OR ValidTo IS NULL) AND (ValidFrom < @ValidFrom)

		UPDATE PumpSetup
		SET	ProductID = @ProductID,
		LocationID = @LocationID,
		ValidFrom = @ValidFrom,
		ValidTo = @ValidTo,
		InUse = @InUse
		WHERE EDISID = @EDISID and Pump = @Pump AND ValidFrom = (SELECT MAX(ValidFrom) FROM PumpSetup WHERE EDISID = @EDISID and Pump = @Pump)
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
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdatePumpSetup] TO PUBLIC
    AS [dbo];

