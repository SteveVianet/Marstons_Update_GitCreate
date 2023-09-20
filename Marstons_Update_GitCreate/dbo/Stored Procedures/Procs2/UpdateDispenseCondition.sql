CREATE PROCEDURE [dbo].[UpdateDispenseCondition]
(
       @EDISID                    INTEGER, 
       @Date                      DATETIME,
       @Pump                INT,
       @StartTime                 DATETIME,
       @NewLiquidType             INT
)

AS

/* For Testing */
--DECLARE       @EDISID                    INT = 1601
--DECLARE       @Date                      DATETIME = '2016-06-15 00:00:00'
--DECLARE       @Pump						 INT = 3
--DECLARE       @StartTime                 DATETIME = '1899-12-30 22:17:08'
--DECLARE       @NewLiquidType             INT = 5


DECLARE @DateAndTime DATETIME
SET @DateAndTime = @Date + CONVERT(VARCHAR(10), @StartTime, 8)

UPDATE dbo.DispenseActions
SET    LiquidType = @NewLiquidType,
OriginalLiquidType = ISNULL(OriginalLiquidType,LiquidType)
WHERE EDISID = @EDISID
AND Pump = @Pump
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

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateDispenseCondition] TO PUBLIC
    AS [dbo];

