CREATE TABLE [dbo].[FlowmeterConfiguration] (
    [EDISID]          INT           NOT NULL,
    [FontNumber]      INT           NOT NULL,
    [ProductID]       INT           NOT NULL,
    [PhysicalAddress] INT           NOT NULL,
    [GlobalProductID] INT           NULL,
    [Memory]          VARCHAR (150) NULL,
    [Version]         INT           NULL,
    [IsCask]          BIT           DEFAULT ((0)) NULL
);

