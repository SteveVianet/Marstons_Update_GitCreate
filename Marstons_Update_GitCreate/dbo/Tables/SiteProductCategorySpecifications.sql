CREATE TABLE [dbo].[SiteProductCategorySpecifications] (
    [EDISID]                       INT NOT NULL,
    [ProductCategoryID]            INT NOT NULL,
    [MinimumPouringYield]          INT CONSTRAINT [DF_SiteProductCategorySpecifications_MinimumYieldPercent] DEFAULT ((100)) NOT NULL,
    [MaximumPouringYield]          INT CONSTRAINT [DF_SiteProductCategorySpecifications_MaximumPouringYield] DEFAULT ((100)) NOT NULL,
    [HighPouringYieldErrThreshold] INT DEFAULT ((107)) NULL,
    [LowPouringYieldErrThreshold]  INT DEFAULT ((95)) NULL
);

