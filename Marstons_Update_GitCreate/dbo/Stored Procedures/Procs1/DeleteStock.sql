CREATE PROCEDURE [dbo].[DeleteStock]
(
	@EDISID 	INTEGER, 
	@Date		DATETIME,
	@ProductID	INTEGER = NULL,
    @MasterDateID INT = NULL,
	@Hour INT = NULL
)

AS

SET NOCOUNT ON

DECLARE @GlobalEDISID	INTEGER
DECLARE @GlobalProductID	INTEGER

IF @MasterDateID IS NULL
BEGIN
SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date
END

DELETE
FROM dbo.Stock
WHERE MasterDateID = @MasterDateID
AND (ProductID = @ProductID OR @ProductID IS NULL)
AND ([Hour] = @Hour OR @Hour IS NULL)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteStock] TO PUBLIC
    AS [dbo];

