CREATE TABLE [dbo].[WebSiteTLThroughput] (
    [EDISID]               INT          NOT NULL,
    [Pump]                 INT          NOT NULL,
    [Product]              VARCHAR (50) NOT NULL,
    [Category]             VARCHAR (50) NOT NULL,
    [AvgVolumePerWeek]     FLOAT (53)   NOT NULL,
    [TotalCleaningWastage] FLOAT (53)   NOT NULL,
    [IsCask]               BIT          NOT NULL
);

