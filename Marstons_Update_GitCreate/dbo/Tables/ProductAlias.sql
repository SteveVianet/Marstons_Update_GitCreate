CREATE TABLE [dbo].[ProductAlias] (
    [ProductID]        INT          NOT NULL,
    [Alias]            VARCHAR (50) NOT NULL,
    [CreatedBy]        VARCHAR (50) CONSTRAINT [DF_ProductAlias_CreatedBy] DEFAULT (suser_sname()) NULL,
    [CreatedOn]        DATETIME     CONSTRAINT [DF_ProductAlias_CreatedOn] DEFAULT (getdate()) NULL,
    [VolumeMultiplier] FLOAT (53)   DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_ProductAlias] PRIMARY KEY CLUSTERED ([ProductID] ASC, [Alias] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProductAlias_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]) ON DELETE CASCADE
);

