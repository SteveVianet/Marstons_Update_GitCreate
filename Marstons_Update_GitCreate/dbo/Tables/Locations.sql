CREATE TABLE [dbo].[Locations] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (30) NOT NULL,
    [GlobalID]    INT          DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_Locations_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

