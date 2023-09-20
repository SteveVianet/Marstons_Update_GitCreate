CREATE TABLE [dbo].[WebSiteTLEquipment] (
    [EDISID]             INT          NOT NULL,
    [Name]               VARCHAR (50) NOT NULL,
    [EquipmentTypeID]    INT          NOT NULL,
    [EquipmentSubTypeID] INT          NOT NULL,
    [Type]               VARCHAR (50) NOT NULL,
    [Location]           VARCHAR (50) NOT NULL,
    [Temperature]        FLOAT (53)   NOT NULL,
    [HasRedTLReadings]   BIT          NOT NULL,
    [HasAmberTLReadings] BIT          NOT NULL,
    [AlertNoData]        BIT          NOT NULL,
    [AlertDate]          DATETIME     NULL,
    [AlertValue]         FLOAT (53)   NULL
);

