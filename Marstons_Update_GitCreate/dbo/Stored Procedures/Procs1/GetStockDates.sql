
CREATE PROCEDURE dbo.GetStockDates
(
	@EDISID	INTEGER
)

AS

SELECT MasterDates.[Date]
FROM dbo.MasterDates
JOIN dbo.Stock ON Stock.MasterDateID = MasterDates.[ID]
WHERE MasterDates.EDISID = @EDISID
GROUP BY MasterDates.[Date]
ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetStockDates] TO PUBLIC
    AS [dbo];

