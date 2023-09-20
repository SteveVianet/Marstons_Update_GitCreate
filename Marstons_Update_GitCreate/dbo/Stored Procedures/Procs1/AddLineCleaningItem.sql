CREATE PROCEDURE AddLineCleaningItem
(
	@EDISID         INT,
	@Date		SMALLDATETIME,
	@Implied	BIT
)

AS

DECLARE @Existing INT
SET @Existing = (SELECT COUNT(EDISID) FROM LineCleaning WHERE EDISID = @EDISID AND Date = @Date)

IF @Existing = 0 --Dont add duplicate items
BEGIN
	INSERT INTO dbo.LineCleaning
	(UserName, EDISID, [Date], Implied, Viewed)
	VALUES
	(SYSTEM_USER, @EDISID, @Date, CAST(@Implied AS INT), 0)
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddLineCleaningItem] TO PUBLIC
    AS [dbo];

