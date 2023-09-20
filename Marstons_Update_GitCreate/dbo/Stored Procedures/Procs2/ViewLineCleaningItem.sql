CREATE PROCEDURE ViewLineCleaningItem
(
	@EDISID		INT,
	@Date		SMALLDATETIME,
	@Implied	BIT
)

AS

UPDATE dbo.LineCleaning
SET Viewed = 1, ViewedBy = SYSTEM_USER
WHERE EDISID = @EDISID
AND [Date] = @Date
AND Implied = CAST(@Implied AS INT)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ViewLineCleaningItem] TO PUBLIC
    AS [dbo];

