CREATE TABLE [dbo].[ProposedFontSetups] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]              INT           NOT NULL,
    [UserName]            VARCHAR (255) CONSTRAINT [DF_ProposedFontSetups_UserName] DEFAULT (suser_sname()) NOT NULL,
    [CreateDate]          DATETIME      CONSTRAINT [DF_ProposedFontSetups_CreateDate] DEFAULT (getdate()) NOT NULL,
    [Completed]           BIT           CONSTRAINT [DF_ProposedFontSetups_Completed] DEFAULT (0) NOT NULL,
    [StockDelivered]      BIT           CONSTRAINT [DF_ProposedFontSetups_StockDelivered] DEFAULT (0) NOT NULL,
    [StockDay]            SMALLINT      CONSTRAINT [DF_ProposedFontSetups_StockDay] DEFAULT (0) NOT NULL,
    [LineCleanDay]        SMALLINT      CONSTRAINT [DF_ProposedFontSetups_LineCleanDay] DEFAULT (0) NOT NULL,
    [DispenseDataCleared] BIT           CONSTRAINT [DF_ProposedFontSetups_DispenseDataCleared] DEFAULT (0) NOT NULL,
    [Comment]             TEXT          NULL,
    [CallID]              INT           NULL,
    [Calibrator]          VARCHAR (255) CONSTRAINT [DF_ProposedFontSetups_Calibrator] DEFAULT (suser_sname()) NULL,
    [FlowmetersUsed]      INT           DEFAULT (0) NOT NULL,
    [TamperCapsUsed]      INT           DEFAULT (0) NOT NULL,
    [PowerSupplyType]     INT           DEFAULT (0) NOT NULL,
    [Available]           BIT           DEFAULT (0) NOT NULL,
    [GlasswareStateID]    INT           DEFAULT (0) NOT NULL,
    [CAMEngineerID]       INT           DEFAULT (null) NULL,
    CONSTRAINT [PK_ProposedFontSetups] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProposedFontSetups_EDISID] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE NONCLUSTERED INDEX [IX_ProposedFontSetups]
    ON [dbo].[ProposedFontSetups]([EDISID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [missing_index_2353_2352_ProposedFontSetups]
    ON [dbo].[ProposedFontSetups]([CreateDate] ASC)
    INCLUDE([EDISID], [GlasswareStateID]);

