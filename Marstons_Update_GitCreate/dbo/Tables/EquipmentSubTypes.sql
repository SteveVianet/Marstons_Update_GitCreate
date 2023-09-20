CREATE TABLE [dbo].[EquipmentSubTypes] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_EquipmentSubTypes] PRIMARY KEY CLUSTERED ([ID] ASC)
);

