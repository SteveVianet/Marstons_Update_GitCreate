CREATE TABLE [dbo].[WebSiteTLTillYield] (
    [EDISID]          INT          NOT NULL,
    [Product]         VARCHAR (50) NOT NULL,
    [Percent]         INT          NOT NULL,
    [IsCask]          BIT          NOT NULL,
    [Sold]            FLOAT (53)   NOT NULL,
    [CashValue]       MONEY        NOT NULL,
    [RetailDispensed] FLOAT (53)   NULL
);

