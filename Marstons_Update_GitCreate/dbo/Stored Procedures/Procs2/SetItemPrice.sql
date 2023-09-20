---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE SetItemPrice
(
	@ItemID		INT,
	@NewPrice	MONEY
)

AS

IF EXISTS(SELECT ItemID FROM ItemPrices WHERE ItemID = @ItemID)
	UPDATE ItemPrices
	SET Price = @NewPrice
	WHERE ItemID = @ItemID
ELSE
	INSERT INTO ItemPrices
	(ItemID, Price)
	VALUES
	(@ItemID, @NewPrice)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetItemPrice] TO PUBLIC
    AS [dbo];

