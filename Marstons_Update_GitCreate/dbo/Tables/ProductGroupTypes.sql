CREATE TABLE [dbo].[ProductGroupTypes] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (255) NOT NULL,
    [OverrideProduct] BIT           DEFAULT (0) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

