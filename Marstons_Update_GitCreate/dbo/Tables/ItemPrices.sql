﻿CREATE TABLE [dbo].[ItemPrices] (
    [ItemID] INT   NOT NULL,
    [Price]  MONEY NOT NULL,
    CONSTRAINT [PK_ItemCosts] PRIMARY KEY CLUSTERED ([ItemID] ASC) WITH (FILLFACTOR = 90)
);

