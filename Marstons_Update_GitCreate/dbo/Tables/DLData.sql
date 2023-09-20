CREATE TABLE [dbo].[DLData] (
    [DownloadID] INT        NOT NULL,
    [Pump]       INT        NOT NULL,
    [Shift]      INT        NOT NULL,
    [Product]    INT        NOT NULL,
    [Quantity]   FLOAT (53) NOT NULL,
    [Amended]    SMALLINT   CONSTRAINT [DLData_Amended] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_DLData] PRIMARY KEY CLUSTERED ([DownloadID] ASC, [Pump] ASC, [Shift] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DLData_MasterDates] FOREIGN KEY ([DownloadID]) REFERENCES [dbo].[MasterDates] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_DLData_Products] FOREIGN KEY ([Product]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_DLData_DownloadID_Product]
    ON [dbo].[DLData]([DownloadID] ASC, [Product] ASC) WITH (FILLFACTOR = 90);

