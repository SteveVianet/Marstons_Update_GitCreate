CREATE PROCEDURE dbo.UpdateDispense
(
	@EDISID 	INTEGER, 
	@Date		DATETIME,
	@Pump		INTEGER,
	@Shift		INTEGER,
	@Product	INTEGER,
	@Quantity	REAL
)

AS

DECLARE @DownloadID	INTEGER
DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

SELECT @DownloadID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @Product IS NULL
BEGIN
	UPDATE dbo.DLData
	SET	Quantity = @Quantity
	WHERE DownloadID = @DownloadID
	AND Pump = @Pump
	AND Shift = @Shift

END
ELSE
BEGIN
	UPDATE dbo.DLData
	SET	Quantity = @Quantity,
		Product = @Product
	WHERE DownloadID = @DownloadID
	AND Pump = @Pump
	AND Shift = @Shift

END

/*
SELECT @GlobalEDISID = GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

IF @GlobalEDISID IS NOT NULL
BEGIN
	SELECT @GlobalProductID = GlobalID
	FROM Products
	WHERE [ID] = @Product

	EXEC [SQL2\SQL2].[Global].dbo.UpdateDispense @GlobalEDISID, @Date, @Pump, @Shift, @GlobalProductID, @Quantity
END
*/


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateDispense] TO PUBLIC
    AS [dbo];

