CREATE TABLE [dbo].[SiteContracts] (
    [EDISID]     INT NOT NULL,
    [ContractID] INT NOT NULL,
    CONSTRAINT [PK_SiteContracts] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ContractID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteContracts_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID]),
    CONSTRAINT [FK_SiteContracts_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

