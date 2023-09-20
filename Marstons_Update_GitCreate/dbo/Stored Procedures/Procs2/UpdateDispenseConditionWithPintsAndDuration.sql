CREATE PROCEDURE [dbo].[UpdateDispenseConditionWithPintsAndDuration] 
	@EDISID			INTEGER, 
    @Date			DATETIME,
    @Pump           INT,
    @StartTime		DATETIME,
	@Pints	        FLOAT,
    @Duration	    FLOAT,
    @NewLiquidType  INT
AS
BEGIN

	DECLARE @DateAndTime DATETIME
	SET @DateAndTime = @Date + CONVERT(VARCHAR(10), @StartTime, 8)

	UPDATE dbo.DispenseActions
	SET    LiquidType = @NewLiquidType,
	OriginalLiquidType = ISNULL(OriginalLiquidType,LiquidType)
	WHERE EDISID = @EDISID
	AND Pump = @Pump
	AND ( -- try two methods, to handle the rounding going in either direction in VB6
         (ROUND(Pints, 2) = ROUND(@Pints, 2)) -- basic rounding, works 99% of the time
        OR
         (ROUND(CAST(CAST(Pints AS VARCHAR(20)) AS DECIMAL(18,2)), 2) = ROUND(@Pints, 2)) -- covers the remaining 1%
         )
	AND (
		-- TFS: 7944 - VB6 cannot provide the level of precision required (milliseconds). So we match to the nearest second rounding up/down as appropriate.
		(DATEPART(MILLISECOND, StartTime) <> 500 AND 
			CAST(StartTime AS DATETIME2(0)) = @DateAndTime)
		OR
		-- TFS: 8198 -  For 500 milliseconds, VB6 rounds completely at random. So we just do whatever we can to figure out what it really wants.
		(DATEPART(MILLISECOND, StartTime) = 500 AND 
			((DATEADD(SECOND, -1, CAST(StartTime AS DATETIME2(0))) = @DateAndTime) 
				OR 
			(CAST(StartTime AS DATETIME2(0)) = @DateAndTime)))
		)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateDispenseConditionWithPintsAndDuration] TO PUBLIC
    AS [dbo];

