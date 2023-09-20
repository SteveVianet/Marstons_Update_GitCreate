CREATE PROCEDURE dbo.DeleteCleaningStack
(
	@EDISID		INT,
	@Date		DATETIME,
	@Time		DATETIME = NULL,
	@Line		INT = NULL
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER

DELETE dbo.CleaningStack
FROM dbo.CleaningStack
JOIN dbo.MasterDates ON MasterDates.[ID] = CleaningStack.CleaningID
WHERE MasterDates.EDISID = @EDISID
AND MasterDates.[Date] = @Date
AND ( dbo.fnTimePart(CleaningStack.[Time]) = dbo.fnTimePart(@Time) OR @Time IS NULL )
AND ( CleaningStack.Line = @Line OR @Line IS NULL )

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeleteCleaningStack @GlobalEDISID, @Date, @Time, @Line
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteCleaningStack] TO PUBLIC
    AS [dbo];

