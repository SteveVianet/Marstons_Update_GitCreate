CREATE TABLE [dbo].[VRSActions] (
    [ID]          INT           NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_VRSActions_ID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

