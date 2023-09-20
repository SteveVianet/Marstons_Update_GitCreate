CREATE TABLE [dbo].[EquipmentReadings] (
    [EDISID]          INT        NOT NULL,
    [InputID]         INT        NOT NULL,
    [LogDate]         DATETIME   NOT NULL,
    [TradingDate]     DATETIME   NOT NULL,
    [LocationID]      INT        NOT NULL,
    [EquipmentTypeID] INT        NOT NULL,
    [Value]           FLOAT (53) NOT NULL,
    CONSTRAINT [PK_EquipmentReadings] PRIMARY KEY CLUSTERED ([EDISID] ASC, [InputID] ASC, [LogDate] ASC),
    CONSTRAINT [FK_EquipmentReadings_EquipmentTypes] FOREIGN KEY ([EquipmentTypeID]) REFERENCES [dbo].[EquipmentTypes] ([ID]),
    CONSTRAINT [FK_EquipmentReadings_Locations] FOREIGN KEY ([LocationID]) REFERENCES [dbo].[Locations] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [missing_index_1616_1615_EquipmentReadings]
    ON [dbo].[EquipmentReadings]([LogDate] ASC)
    INCLUDE([EDISID], [InputID], [EquipmentTypeID], [Value]);

