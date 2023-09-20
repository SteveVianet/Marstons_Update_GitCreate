CREATE PROCEDURE [dbo].[UpdateSiteDispenseActionsByShift]
(
	@EDISID				INT,
	@DispenseDate		DATETIME,
	@Pump				INT,
	@Shift				INT,
	@NewLiquidTypeID	INT
)
AS

--Note: This procedure does not support site groups as it will be called by the Line Cleaning Service & related software
--Note: DispenseDate is actual date, not trading date

SET NOCOUNT ON

/* Only update and refresh data when DispenseActions contains data to change. Otherwise ignore the request. */
IF EXISTS(SELECT TOP 1 1 FROM DispenseActions WHERE EDISID = @EDISID AND CAST(StartTime AS DATE) = @DispenseDate)
BEGIN
    UPDATE DispenseActions
    SET OriginalLiquidType = LiquidType, LiquidType = @NewLiquidTypeID
    WHERE EDISID = @EDISID
    AND CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, StartTime))) = @DispenseDate
    AND Pump = @Pump
    AND DATEPART(HOUR, StartTime) = @Shift-1

    DECLARE @DayToRefresh SMALLDATETIME = CAST(@DispenseDate AS DATE)

    EXEC RebuildStacksFromDispenseConditions NULL, @EDISID, @DayToRefresh, @DayToRefresh, @Pump    
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteDispenseActionsByShift] TO PUBLIC
    AS [dbo];

