CREATE TABLE [dbo].[CallLines] (
    [CallID]          INT           NOT NULL,
    [LineNumber]      INT           NOT NULL,
    [Location]        VARCHAR (255) NOT NULL,
    [VolumeDispensed] FLOAT (53)    NOT NULL,
    [Product]         VARCHAR (255) NULL,
    CONSTRAINT [PK_CallLines] PRIMARY KEY CLUSTERED ([CallID] ASC, [LineNumber] ASC),
    FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

