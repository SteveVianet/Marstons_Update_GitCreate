CREATE PROCEDURE [dbo].[AddEquipmentLog]
(
	@EDISID		INT,
	@Date			DATETIME,
	@Time			DATETIME,
	@SlaveID		INT = 0,
	@IsDigital		BIT = 0,
	@InputID		INT,
	@LocationID		INT = NULL,
	@EquipmentTypeID	INT = NULL,
	@BaseValue		FLOAT
)

AS

SET NOCOUNT ON

--DECLARE @MasterDateID		INT
DECLARE @GlobalEDISID		INT
DECLARE @GlobalLocationID		INT
DECLARE @ReadingDateTime		DATETIME
DECLARE @ReadingTradingDateTime	DATETIME

/* 2010-07-22: If no one complains, delete this portion of code and the MasterDateID declaration above

-- Find MasterDate, adding it if we need to
SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

IF @MasterDateID IS NULL
BEGIN
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)

	SET @MasterDateID = @@IDENTITY
END
*/

-- We check these as a pair, since a caller will supply both or none of these (never just one)
IF (@LocationID IS NULL AND @EquipmentTypeID IS NULL)
BEGIN
	SELECT @LocationID = LocationID, @EquipmentTypeID = EquipmentTypeID
	FROM dbo.EquipmentItems
	WHERE EDISID = @EDISID
	AND InputID = @InputID

END

IF (@LocationID IS NOT NULL) AND (@EquipmentTypeID IS NOT NULL)
BEGIN
	--Work out full dates and add to new EquipmentReadings table
	SET @ReadingDateTime = @Date + CONVERT(VARCHAR(10), @Time, 8)
	SELECT @ReadingTradingDateTime = CASE WHEN DATEPART(Hour, @Time) < 5 THEN DATEADD(Day, -1, @Date) ELSE @Date END + 
CONVERT(VARCHAR(10), @Time, 8)

	INSERT INTO dbo.EquipmentReadings
	(EDISID, InputID, LogDate, TradingDate, LocationID, EquipmentTypeID, Value)
	VALUES
	(@EDISID, @InputID, @ReadingDateTime, @ReadingTradingDateTime, @LocationID, @EquipmentTypeID, @BaseValue)

	/*
	SELECT @GlobalEDISID = GlobalEDISID
	FROM Sites
	WHERE EDISID = @EDISID

	IF @GlobalEDISID IS NOT NULL
	BEGIN
		SELECT @GlobalLocationID = GlobalID
		FROM Locations
		WHERE [ID] = @LocationID

		EXEC [SQL2\SQL2].[Global].dbo.AddEquipmentLog @GlobalEDISID, @Date, @Time, @SlaveID, @IsDigital, @InputID, 
@GlobalLocationID, @EquipmentTypeID, @BaseValue

	END
	*/
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddEquipmentLog] TO PUBLIC
    AS [dbo];

