CREATE PROCEDURE RemoveNilDelivery
(
	@EDISID 	INTEGER, 
	@Date		DATETIME
)

AS

DECLARE @MasterDateID	INTEGER

SELECT @MasterDateID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

DELETE FROM dbo.NilDeliveries 
WHERE MasterDateID = @MasterDateID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RemoveNilDelivery] TO PUBLIC
    AS [dbo];

