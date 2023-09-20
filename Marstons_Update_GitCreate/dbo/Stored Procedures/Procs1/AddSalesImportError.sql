CREATE PROCEDURE [dbo].[AddSalesImportError]
(
      @SiteID     VARCHAR(50),
      @Date       SMALLDATETIME,
      @SaleIdent  VARCHAR(255),
      @ProductAlias     VARCHAR(50),
      @Message    VARCHAR(255),
      @Quantity   FLOAT,
      @SaleTime   DATETIME
)

AS

INSERT INTO dbo.SalesImportErrors
(UserName, Message, SiteID, [Date], SaleIdent, ProductAlias, Quantity, SaleTime)
VALUES
(SYSTEM_USER, @Message, @SiteID, @Date, @SaleIdent, @ProductAlias, @Quantity, @SaleTime)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSalesImportError] TO PUBLIC
    AS [dbo];

