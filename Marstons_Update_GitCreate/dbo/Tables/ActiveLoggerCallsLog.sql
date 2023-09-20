CREATE TABLE [dbo].[ActiveLoggerCallsLog] (
    [ID]            INT           NOT NULL,
    [Time]          DATETIME      NOT NULL,
    [RefreshUser]   VARCHAR (100) NOT NULL,
    [CallID]        INT           NULL,
    [RefreshedFrom] VARCHAR (100) NULL
);

