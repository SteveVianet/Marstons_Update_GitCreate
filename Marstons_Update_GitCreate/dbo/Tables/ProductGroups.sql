CREATE TABLE [dbo].[ProductGroups] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    [TypeID]      INT           DEFAULT (1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ProductGroups_ProductGroupTypes] FOREIGN KEY ([TypeID]) REFERENCES [dbo].[ProductGroupTypes] ([ID])
);

