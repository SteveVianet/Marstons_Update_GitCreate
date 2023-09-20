CREATE TABLE [dbo].[CleaningSystems] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [Description]          VARCHAR (50) NOT NULL,
    [CleanDaysBeforeAmber] INT          NOT NULL,
    [CleanDaysBeforeRed]   INT          NOT NULL,
    CONSTRAINT [PK_CleaningSystems] PRIMARY KEY CLUSTERED ([ID] ASC)
);

