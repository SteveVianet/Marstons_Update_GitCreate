CREATE TABLE [dbo].[CleaningServiceActions] (
    [MasterDateID] INT NOT NULL,
    CONSTRAINT [PK_CleaningServiceActions] PRIMARY KEY CLUSTERED ([MasterDateID] ASC),
    CONSTRAINT [FK_CleaningServiceActions_MasterDates] FOREIGN KEY ([MasterDateID]) REFERENCES [dbo].[MasterDates] ([ID])
);

