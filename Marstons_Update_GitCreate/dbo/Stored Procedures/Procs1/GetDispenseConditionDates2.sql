CREATE PROCEDURE [dbo].[GetDispenseConditionDates2]
(
	@EDISID	INTEGER,
	@ProductID	INTEGER = NULL
)
AS

--- Fix for parameter sniffing.
DECLARE @InternalEDISID 	INT
DECLARE @InternalProductID 	INT

--- Set internal variables.
SET @InternalEDISID = @EDISID
SET @InternalProductID = @ProductID

SELECT DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))
FROM dbo.DispenseActions
WHERE (DispenseActions.EDISID = @InternalEDISID) AND ((dbo.DispenseActions.Product = @InternalProductID) OR (@InternalProductID IS NULL))
GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))
ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispenseConditionDates2] TO PUBLIC
    AS [dbo];

