CREATE TABLE [dbo].[ProcessIFMLiquidTypesLog] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [LogTime]       DATETIME       CONSTRAINT [LogTimeDefaultToNowUTC] DEFAULT (getdate()) NOT NULL,
    [EDISID]        INT            NOT NULL,
    [Pump]          INT            NOT NULL,
    [DispenseTime]  DATETIME       NOT NULL,
    [OldLiquidType] INT            NOT NULL,
    [NewLiquidType] INT            NOT NULL,
    [LogText]       VARCHAR (1000) NOT NULL
);

