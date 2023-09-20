CREATE TABLE [dbo].[NilDeliveries] (
    [MasterDateID] INT NOT NULL,
    CONSTRAINT [PK_NilDeliveries] PRIMARY KEY CLUSTERED ([MasterDateID] ASC),
    CONSTRAINT [FK_NilDeliveries_MasterDates] FOREIGN KEY ([MasterDateID]) REFERENCES [dbo].[MasterDates] ([ID])
);

