CREATE TABLE [dbo].[JobWatchCallsData] (
    [JobId]            INT NOT NULL,
    [CallReasonTypeID] INT NOT NULL,
    [EquipmentAddress] INT NULL,
    [IFMAddress]       INT NULL,
    [Pump]             INT NULL,
    [ProductID]        INT NULL,
    CONSTRAINT [FK_JobWatchCallsData_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ID])
);

