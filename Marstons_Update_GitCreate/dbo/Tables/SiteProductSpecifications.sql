CREATE TABLE [dbo].[SiteProductSpecifications] (
    [EDISID]               INT        NOT NULL,
    [ProductID]            INT        NOT NULL,
    [CleanDaysBeforeAmber] INT        NULL,
    [CleanDaysBeforeRed]   INT        NULL,
    [TempSpec]             FLOAT (53) NULL,
    [TempTolerance]        FLOAT (53) NULL,
    [FlowSpec]             FLOAT (53) NULL,
    [FlowTolerance]        FLOAT (53) NULL,
    CONSTRAINT [PK_SiteProductSpecifications] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ProductID] ASC)
);

