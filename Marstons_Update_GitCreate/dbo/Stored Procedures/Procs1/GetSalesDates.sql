
CREATE PROCEDURE GetSalesDates
(
	@EDISID	INTEGER
)

AS

SELECT MasterDates.[Date]
FROM dbo.MasterDates
JOIN dbo.Sales
ON Sales.MasterDateID = MasterDates.[ID]
WHERE MasterDates.EDISID = @EDISID
GROUP BY MasterDates.[Date]
ORDER BY MasterDates.[Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSalesDates] TO PUBLIC
    AS [dbo];

