CREATE TABLE [dbo].[SiteVRSAuthorisedBuyingOut] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]            INT           NOT NULL,
    [ProductID]         INT           NOT NULL,
    [AuthorisationDate] DATE          NOT NULL,
    [QuantityGallons]   FLOAT (53)    NOT NULL,
    [Filename]          VARCHAR (500) NULL,
    [ImportedOn]        DATETIME      NULL,
    [ImportedBy]        VARCHAR (100) NULL,
    CONSTRAINT [PK_SiteVRSAuthorisedBuyingOut_1] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_SiteVRSAuthorisedBuyingOut_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_SiteVRSAuthorisedBuyingOut_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

