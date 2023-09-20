CREATE TABLE [dbo].[SiteProductIFMSetpoints] (
    [EDISID]    INT           NOT NULL,
    [ProductID] INT           NOT NULL,
    [Setpoint]  VARCHAR (150) NOT NULL,
    [Pump]      INT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [FK_SiteProductIFMSetpoints_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_SiteProductIFMSetpoints_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

