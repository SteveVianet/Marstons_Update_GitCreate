CREATE PROCEDURE dbo.DeleteWaterStack
(
	@EDISID		INT,
	@Date		DATETIME,
	@Time		DATETIME = NULL,
	@Line		INT = NULL
)

AS

DECLARE @GlobalEDISID	INTEGER

SET NOCOUNT ON

DELETE dbo.WaterStack
FROM dbo.WaterStack
JOIN dbo.MasterDates ON MasterDates.[ID] = WaterStack.WaterID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] = @Date
AND ( dbo.fnTimePart(WaterStack.[Time]) = dbo.fnTimePart(@Time) OR @Time IS NULL )
AND ( WaterStack.Line = @Line OR @Line IS NULL )

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeleteWaterStack @GlobalEDISID, @Date, @Time, @Line
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteWaterStack] TO PUBLIC
    AS [dbo];

