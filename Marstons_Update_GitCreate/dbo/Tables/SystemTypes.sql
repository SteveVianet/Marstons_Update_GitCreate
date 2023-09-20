CREATE TABLE [dbo].[SystemTypes] (
    [ID]               INT           NOT NULL,
    [Description]      VARCHAR (255) NOT NULL,
    [DispenseByMinute] BIT           NULL,
    CONSTRAINT [PK_SystemTypes] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_SystemTypes] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

