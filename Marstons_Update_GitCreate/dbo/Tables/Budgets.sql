CREATE TABLE [dbo].[Budgets] (
    [EDISID]   INT        NULL,
    [WeekNo]   INT        NULL,
    [Quantity] FLOAT (53) NULL,
    CONSTRAINT [FK_Budgets_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);

