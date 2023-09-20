CREATE PROCEDURE [dbo].[UpdateSiteDispenseActionLiquidType]
(
	@EDISID				INT,
	@DispenseDate		DATETIME,
	@Pump				INT,
	@NewLiquidTypeID	INT
)
AS

--Note: This procedure does not support site groups as it will be called by the Line Cleaning Service & related software
--Note: DispenseDate is actual date, not trading date

SET NOCOUNT ON

/*  As it's possible for a Site can switch between DispenseActions and Stack based data depending on the SystemType and configuration, we need 
     a reliable way of identifying whether we should trust the DispenseActions for the affected period or not. 
    
    Can we rely on install/online dates historically?
        No. Unless we are within the last install these dates define, we don't have enough information to know what past data *should* look like.
        Information might be available in ServiceCalls (not confirmed, potentially awkward to query) or manually entered text strings (unreliable).
    Or do we rely on the data only ignoring the Site setup? 
        I'm 99% confident in doing it this way based on how Gateway 3 and Comtech appear to treat mixed-meter installs.
        Non GW3/Comtech sites store data in either Stack tables for DispenseActions (generating Stack data)
        GW3 always stores data in DispenseActions (generating Stack data).
        Comtech changes depending on the configuration, but crucially in a mixed-meter setup it does stores data in DispenseActions (generating Stack data).
            Do we only test DispenseActions?
                Can we trust thise for mixed meter sites?
                Gateway 3   - Yes
                Comtech     - Yes

    EDIS 2 - Only 
*/

/* Only update and refresh data when DispenseActions contains data to change. Otherwise ignore the request. */
IF EXISTS(SELECT TOP 1 1 FROM DispenseActions WHERE EDISID = @EDISID AND StartTime = @DispenseDate)
BEGIN
    UPDATE DispenseActions
    SET OriginalLiquidType = LiquidType, LiquidType = @NewLiquidTypeID
    WHERE EDISID = @EDISID
    AND StartTime = @DispenseDate
    AND Pump = @Pump

    DECLARE @DayToRefresh SMALLDATETIME = CAST(@DispenseDate AS DATE)

    EXEC RebuildStacksFromDispenseConditions NULL, @EDISID, @DayToRefresh, @DayToRefresh, @Pump    
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteDispenseActionLiquidType] TO PUBLIC
    AS [dbo];

