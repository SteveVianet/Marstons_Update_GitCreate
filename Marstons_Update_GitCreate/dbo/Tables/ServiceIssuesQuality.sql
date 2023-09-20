CREATE TABLE [dbo].[ServiceIssuesQuality] (
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    [EDISID]           INT      NOT NULL,
    [CallID]           INT      NOT NULL,
    [PumpID]           INT      NOT NULL,
    [ProductID]        INT      NOT NULL,
    [PrimaryProductID] INT      NOT NULL,
    [DateFrom]         DATETIME NOT NULL,
    [DateTo]           DATETIME NULL,
    [RealPumpID]       INT      NOT NULL,
    [RealEDISID]       INT      NOT NULL,
    [CallReasonTypeID] INT      NOT NULL,
    CONSTRAINT [PK_ServiceIssuesQuality] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ServiceIssuesQuality_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID]),
    CONSTRAINT [FK_ServiceIssuesQuality_Products] FOREIGN KEY ([PrimaryProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_ServiceIssuesQuality_Products1] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_ServiceIssuesQuality_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

