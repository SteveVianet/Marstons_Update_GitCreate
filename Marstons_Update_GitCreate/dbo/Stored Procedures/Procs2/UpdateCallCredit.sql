CREATE PROCEDURE [dbo].[UpdateCallCredit]
(
	@CallID				INT,
	@CreditDate			DATETIME = 0,
	@CreditAmount		MONEY = 0
)

AS

UPDATE dbo.Calls
SET CreditDate = @CreditDate,
	CreditAmount = @CreditAmount
WHERE [ID] = @CallID

EXEC dbo.RefreshHandheldCall @CallID, 1, 1, 1

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallCredit] TO PUBLIC
    AS [dbo];

