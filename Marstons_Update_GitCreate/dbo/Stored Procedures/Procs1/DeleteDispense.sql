CREATE PROCEDURE dbo.DeleteDispense
(
	@EDISID		INT,
	@Date		DATETIME,
	@Pump		INT = NULL,
	@Shift		INT = NULL
)

AS

DECLARE @DownloadID	INT
DECLARE @GlobalEDISID	INT

SELECT @DownloadID = [ID]
FROM dbo.MasterDates
WHERE [Date] = @Date
AND EDISID = @EDISID

DELETE FROM dbo.DLData
WHERE DownloadID = @DownloadID
AND ( Pump = @Pump OR @Pump IS NULL )
AND ( Shift = @Shift OR @Shift IS NULL )

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	EXEC [SQL2\SQL2].[Global].dbo.DeleteDispense @GlobalEDISID, @Date, @Pump, @Shift
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteDispense] TO PUBLIC
    AS [dbo];

