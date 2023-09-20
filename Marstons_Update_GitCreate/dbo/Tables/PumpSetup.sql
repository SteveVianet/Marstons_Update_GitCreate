CREATE TABLE [dbo].[PumpSetup] (
    [EDISID]           INT           NOT NULL,
    [Pump]             INT           NOT NULL,
    [ProductID]        INT           NOT NULL,
    [LocationID]       INT           NOT NULL,
    [ValidFrom]        DATETIME      NOT NULL,
    [ValidTo]          DATETIME      NULL,
    [InUse]            BIT           CONSTRAINT [DF_PumpSetup_InUse] DEFAULT (1) NOT NULL,
    [BarPosition]      INT           DEFAULT (0) NOT NULL,
    [IFMConfiguration] VARCHAR (150) NULL,
    CONSTRAINT [PK_PumpSetup] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Pump] ASC, [ValidFrom] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_PumpSetup_Locations] FOREIGN KEY ([LocationID]) REFERENCES [dbo].[Locations] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_PumpSetup_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_PumpSetup_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);

