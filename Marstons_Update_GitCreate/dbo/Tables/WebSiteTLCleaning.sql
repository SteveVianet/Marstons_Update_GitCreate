CREATE TABLE [dbo].[WebSiteTLCleaning] (
    [EDISID]          INT          NOT NULL,
    [Product]         VARCHAR (50) NOT NULL,
    [Location]        VARCHAR (50) NOT NULL,
    [Volume]          FLOAT (53)   NOT NULL,
    [LastClean]       DATETIME     NOT NULL,
    [IsCask]          BIT          NOT NULL,
    [DaysBeforeAmber] INT          NOT NULL,
    [DaysBeforeRed]   INT          NOT NULL,
    [Pump]            INT          NULL,
    [Issue]           BIT          DEFAULT ((1)) NOT NULL
);

