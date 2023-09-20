CREATE PROCEDURE GetNilDelivery
(
	@EDISID 	INTEGER
)

AS

SELECT [Date]
FROM dbo.MasterDates
JOIN NilDeliveries ON NilDeliveries.MasterDateID = MasterDates.ID
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNilDelivery] TO PUBLIC
    AS [dbo];

