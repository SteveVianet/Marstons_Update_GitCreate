CREATE PROCEDURE AddNilDelivery
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

INSERT INTO dbo.NilDeliveries
(MasterDateID)
VALUES
(@MasterDateID)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddNilDelivery] TO PUBLIC
    AS [dbo];

