CREATE TABLE [dbo].[ServiceIssuesYield] (
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    [EDISID]           INT      NOT NULL,
    [CallID]           INT      NOT NULL,
    [ProductID]        INT      NOT NULL,
    [PrimaryProductID] INT      NOT NULL,
    [DateFrom]         DATETIME NOT NULL,
    [DateTo]           DATETIME NULL,
    [RealEDISID]       INT      NOT NULL,
    [CallReasonTypeID] INT      NOT NULL,
    CONSTRAINT [PK_ServiceIssuesYield] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ServiceIssuesYield_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID]),
    CONSTRAINT [FK_ServiceIssuesYield_Products] FOREIGN KEY ([PrimaryProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_ServiceIssuesYield_Products1] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID]),
    CONSTRAINT [FK_ServiceIssuesYield_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

