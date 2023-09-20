CREATE TABLE [dbo].[LineCleaning] (
    [UserName]  VARCHAR (255) NOT NULL,
    [EDISID]    INT           NOT NULL,
    [Date]      SMALLDATETIME NOT NULL,
    [Implied]   TINYINT       NOT NULL,
    [Viewed]    BIT           NOT NULL,
    [ViewedBy]  VARCHAR (255) NULL,
    [Processed] BIT           CONSTRAINT [AddProcessedDft] DEFAULT (0) NULL,
    CONSTRAINT [PK_LineCleaning] PRIMARY KEY NONCLUSTERED ([EDISID] ASC, [Date] ASC)
);


GO
CREATE CLUSTERED INDEX [IX_LineCleaning]
    ON [dbo].[LineCleaning]([EDISID] ASC, [Date] ASC, [Implied] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LineCleaning_UserName]
    ON [dbo].[LineCleaning]([UserName] ASC);


GO
CREATE NONCLUSTERED INDEX [missing_index_2533_2532_LineCleaning]
    ON [dbo].[LineCleaning]([Processed] ASC)
    INCLUDE([EDISID], [Date], [Implied], [Viewed]);

