CREATE TABLE [dbo].[DeliveryImportErrors] (
    [UserName]      VARCHAR (255) NOT NULL,
    [Message]       VARCHAR (255) NOT NULL,
    [SiteID]        VARCHAR (50)  NOT NULL,
    [Date]          SMALLDATETIME NOT NULL,
    [DeliveryIdent] VARCHAR (255) NOT NULL,
    [ProductAlias]  VARCHAR (50)  NOT NULL,
    [Quantity]      FLOAT (53)    NOT NULL
);

