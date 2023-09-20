CREATE TABLE [dbo].[VRSOutcomes] (
    [ID]          INT           NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_VRSOutcomes_ID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

