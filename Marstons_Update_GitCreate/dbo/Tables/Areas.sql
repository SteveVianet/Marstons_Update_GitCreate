CREATE TABLE [dbo].[Areas] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Areas] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_Areas_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

