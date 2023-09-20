CREATE PROCEDURE [dbo].[AddPumpSetup]
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

		DECLARE @NewValidFrom DATE
		SET @NewValidFrom = DATEADD(D, +1,@ValidTo)

		UPDATE PumpSetup
		SET ValidTo = @ChangeExsistingValidTo
		WHERE EDISID = @EDISID AND Pump = @Pump AND (ValidTo > @ValidFrom OR ValidTo IS NULL) AND (ValidFrom < @ValidFrom)

		INSERT INTO PumpSetup(EDISID,Pump,ProductID, LocationID,ValidFrom,ValidTo,InUse,BarPosition)
			SELECT EDISID,Pump,ProductID, LocationID,@NewValidFrom,ValidTo,InUse,BarPosition
			FROM @ExsisitngPumpSetup 

		INSERT INTO PumpSetup(EDISID,Pump,ProductID, LocationID,ValidFrom,ValidTo,InUse,BarPosition)
		VALUES (@EDISID,@Pump,@ProductID, @LocationID, @ValidFrom, @ValidTo, @InUse, 0)

	END
ELSE
	BEGIN
		INSERT INTO PumpSetup(EDISID,Pump,ProductID, LocationID,ValidFrom,ValidTo,InUse,BarPosition)
		VALUES (@EDISID,@Pump,@ProductID, @LocationID, @ValidFrom, @ValidTo, @InUse, 0)
	END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPumpSetup] TO PUBLIC
    AS [dbo];

