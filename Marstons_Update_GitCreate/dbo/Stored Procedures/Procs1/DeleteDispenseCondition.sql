CREATE PROCEDURE [dbo].[DeleteDispenseCondition]
(
	@EDISID 			INTEGER, 
	@Date				DATETIME,
	@Pump				INT = NULL,
	@StartTime			DATETIME = NULL
)

AS

DELETE FROM dbo.DispenseActions
WHERE EDISID = @EDISID
AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) = @Date
AND ( Pump = @Pump OR @Pump IS NULL )
AND ( CONVERT(VARCHAR(10), StartTime, 8) = CONVERT(VARCHAR(10), @StartTime, 8) OR @StartTime IS NULL )

--TODO: Shouldn't we rebuild the evil stacks?

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDispenseCondition] TO PUBLIC
    AS [dbo];

