CREATE PROCEDURE [dbo].[GetDispenseConditionDates]
(
	@EDISID	INTEGER,
	@Pump		INTEGER = NULL
)

AS

--Fix for parameter sniffing
DECLARE @InternalEDISID 	INT
DECLARE @InternalPump 		INT

SET @InternalEDISID = @EDISID
SET @InternalPump = @Pump

SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) AS Date
FROM DispenseActions
WHERE DispenseActions.EDISID = @InternalEDISID
AND (DispenseActions.Pump = @InternalPump OR @InternalPump IS NULL)
GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))
ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditionDates] TO PUBLIC
    AS [dbo];

