CREATE TABLE [dbo].[SiteSpecifications] (
    [EDISID]               INT NOT NULL,
    [CleanDaysBeforeAmber] INT NOT NULL,
    [CleanDaysBeforeRed]   INT NOT NULL,
    CONSTRAINT [PK_SiteSpecifications] PRIMARY KEY CLUSTERED ([EDISID] ASC)
);

