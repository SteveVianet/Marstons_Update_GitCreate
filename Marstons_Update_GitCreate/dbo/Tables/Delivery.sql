CREATE TABLE [dbo].[Delivery] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [DeliveryID]    INT          NOT NULL,
    [Product]       INT          NOT NULL,
    [Quantity]      FLOAT (53)   NULL,
    [DeliveryIdent] VARCHAR (50) NULL,
    [FileID]        INT          NULL,
    CONSTRAINT [PK_Delivery] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Delivery_MasterDates] FOREIGN KEY ([DeliveryID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Delivery_Products] FOREIGN KEY ([Product]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_Delivery_DeliveryID_Product]
    ON [dbo].[Delivery]([DeliveryID] ASC, [Product] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Delivery_DeliveryID_Product_Quantity]
    ON [dbo].[Delivery]([DeliveryID] ASC, [Product] ASC, [Quantity] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Delivery_FileID]
    ON [dbo].[Delivery]([FileID] ASC);

