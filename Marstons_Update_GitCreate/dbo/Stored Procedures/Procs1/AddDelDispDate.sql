---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddDelDispDate
(
	@EDISID INTEGER, 
	@Date	DATETIME
)

AS

DECLARE @DateCount	INTEGER

--Check delivery date does not already exist
SELECT @DateCount = COUNT(*)
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date

IF @DateCount = 0
	INSERT INTO dbo.MasterDates
	(EDISID, [Date])
	VALUES
	(@EDISID, @Date)



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDelDispDate] TO PUBLIC
    AS [dbo];

