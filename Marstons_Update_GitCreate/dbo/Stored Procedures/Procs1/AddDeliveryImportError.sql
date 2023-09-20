---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddDeliveryImportError
(
	@SiteID		VARCHAR(50),
	@Date		SMALLDATETIME,
	@DeliveryIdent	VARCHAR(255),
	@ProductAlias	VARCHAR(50),
	@Message	VARCHAR(255),
	@Quantity	FLOAT
)

AS

INSERT INTO dbo.DeliveryImportErrors
(UserName, Message, SiteID, [Date], DeliveryIdent, ProductAlias, Quantity)
VALUES
(SYSTEM_USER, @Message, @SiteID, @Date, @DeliveryIdent, @ProductAlias, @Quantity)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddDeliveryImportError] TO PUBLIC
    AS [dbo];

