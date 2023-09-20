CREATE TABLE [dbo].[PubcoCalendars] (
    [Cust]                VARCHAR (10) NULL,
    [Period]              VARCHAR (10) NULL,
    [FromWC]              DATE         NULL,
    [ToWC]                DATE         NULL,
    [PeriodWeeks]         INT          NULL,
    [PeriodYear]          VARCHAR (10) NULL,
    [PeriodYearLastYear]  VARCHAR (10) NULL,
    [PeriodLY]            VARCHAR (10) NULL,
    [DatabaseID]          INT          NULL,
    [DatabaseName]        VARCHAR (50) NULL,
    [DatabaseCompanyName] VARCHAR (50) NULL,
    [Processed]           BIT          CONSTRAINT [DF_PubcoCalendars_Processed] DEFAULT ((0)) NOT NULL,
    [PeriodNumber]        INT          NULL
);

