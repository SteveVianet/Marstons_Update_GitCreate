CREATE TABLE [dbo].[SalesImportErrors] (
    [UserName]     VARCHAR (255) NOT NULL,
    [Message]      VARCHAR (255) NOT NULL,
    [SiteID]       VARCHAR (50)  NOT NULL,
    [Date]         SMALLDATETIME NOT NULL,
    [SaleIdent]    VARCHAR (255) NOT NULL,
    [ProductAlias] VARCHAR (50)  NOT NULL,
    [Quantity]     FLOAT (53)    NOT NULL,
    [SaleTime]     DATETIME      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_SalesImportErrors_UserName]
    ON [dbo].[SalesImportErrors]([UserName] ASC);

