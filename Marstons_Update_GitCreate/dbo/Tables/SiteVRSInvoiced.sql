CREATE TABLE [dbo].[SiteVRSInvoiced] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]     INT           NOT NULL,
    [Filename]   VARCHAR (500) NULL,
    [ImportedOn] DATETIME      NULL,
    [ImportedBy] VARCHAR (100) NULL,
    [ChargeDate] DATETIME      NOT NULL,
    CONSTRAINT [PK_SiteVRSInvoiced_1] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_SiteVRSInvoiced_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

