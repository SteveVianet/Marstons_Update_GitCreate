CREATE TABLE [dbo].[WebSiteTLTemperature] (
    [EDISID]             INT          NOT NULL,
    [Pump]               INT          NOT NULL,
    [Product]            VARCHAR (50) NOT NULL,
    [Location]           VARCHAR (50) NOT NULL,
    [AcceptableQuantity] FLOAT (53)   NOT NULL,
    [PoorQuantity]       FLOAT (53)   NOT NULL,
    [IsCask]             BIT          NOT NULL,
    [TotalQuantity]      FLOAT (53)   DEFAULT ((0)) NOT NULL,
    [Specification]      INT          NULL,
    [Tolerance]          INT          NULL
);

