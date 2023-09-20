CREATE PROCEDURE DeleteLineCleaningItem
(
	@EDISID		INT,
	@Date		SMALLDATETIME,
	@Implied	BIT
)

AS

UPDATE dbo.LineCleaning
SET Processed = 1
WHERE EDISID = @EDISID
AND [Date] = @Date
--AND Implied = CAST(@Implied AS INT)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteLineCleaningItem] TO PUBLIC
    AS [dbo];

