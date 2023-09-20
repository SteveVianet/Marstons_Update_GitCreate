CREATE TABLE [dbo].[SiteContractHistory] (
    [EDISID]     INT      NOT NULL,
    [ContractID] INT      NOT NULL,
    [ValidFrom]  DATETIME NOT NULL,
    [ValidTo]    DATETIME NULL,
    CONSTRAINT [PK_SiteContractHistory] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ContractID] ASC, [ValidFrom] ASC),
    CONSTRAINT [FK_SiteContractHistory_Contracts] FOREIGN KEY ([ContractID]) REFERENCES [dbo].[Contracts] ([ID]),
    CONSTRAINT [FK_Sites_SiteContractHistory] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

