CREATE TABLE [dbo].[ProductCategories] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
    [Description]                  VARCHAR (255) NOT NULL,
    [MinimumPouringYield]          INT           CONSTRAINT [DF_ProductCategories_MinimumYieldPercent] DEFAULT ((100)) NOT NULL,
    [MaximumPouringYield]          INT           CONSTRAINT [DF_ProductCategories_MaximumPouringYield] DEFAULT ((100)) NOT NULL,
    [HighPouringYieldErrThreshold] INT           DEFAULT ((107)) NULL,
    [LowPouringYieldErrThreshold]  INT           DEFAULT ((95)) NULL,
    [IncludeInEstateReporting]     BIT           DEFAULT ((1)) NOT NULL,
    [TargetPouringYield]           INT           NULL,
    [IncludeInLineCleaning]        BIT           DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_ProductCategories] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

