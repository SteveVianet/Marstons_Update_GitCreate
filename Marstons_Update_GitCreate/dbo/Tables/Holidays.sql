﻿CREATE TABLE [dbo].[Holidays] (
    [Date] DATETIME      NOT NULL,
    [Name] VARCHAR (255) CONSTRAINT [DF_Holidays_Name] DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([Date] ASC) WITH (FILLFACTOR = 90)
);

