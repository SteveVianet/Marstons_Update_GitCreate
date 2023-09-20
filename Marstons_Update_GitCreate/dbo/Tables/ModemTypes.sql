CREATE TABLE [dbo].[ModemTypes] (
    [ID]          INT           NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_ModemTypes] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_ModemTypes_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

