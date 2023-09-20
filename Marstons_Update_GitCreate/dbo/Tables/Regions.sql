CREATE TABLE [dbo].[Regions] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Regions] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_Regions_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

