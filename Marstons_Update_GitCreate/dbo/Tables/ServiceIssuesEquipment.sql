CREATE TABLE [dbo].[ServiceIssuesEquipment] (
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    [EDISID]           INT      NOT NULL,
    [CallID]           INT      NOT NULL,
    [InputID]          INT      NOT NULL,
    [DateFrom]         DATETIME NOT NULL,
    [DateTo]           DATETIME NULL,
    [RealEDISID]       INT      NOT NULL,
    [CallReasonTypeID] INT      NOT NULL,
    CONSTRAINT [PK_ServiceIssuesEquipment] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ServiceIssuesEquipment_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID]),
    CONSTRAINT [FK_ServiceIssuesEquipment_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

