CREATE TABLE [dbo].[CallFaultSLAs] (
    [FaultTypeID] INT NOT NULL,
    [SLA]         INT NOT NULL,
    CONSTRAINT [PK_CallFaultSLAs] PRIMARY KEY CLUSTERED ([FaultTypeID] ASC)
);

