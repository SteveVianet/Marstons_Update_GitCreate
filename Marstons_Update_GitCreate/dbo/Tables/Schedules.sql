CREATE TABLE [dbo].[Schedules] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (255) NOT NULL,
    [Owner]       VARCHAR (255) CONSTRAINT [DF_Schedules_Owner] DEFAULT (suser_sname()) NOT NULL,
    [Public]      BIT           CONSTRAINT [DF_Schedules_Public] DEFAULT (0) NOT NULL,
    [ExpiryDate]  SMALLDATETIME CONSTRAINT [DF_Schedules_ExpiryDate] DEFAULT (dateadd(day,14,getdate())) NULL,
    [CreatedOn]   SMALLDATETIME DEFAULT (getdate()) NULL,
    [CreatedBy]   VARCHAR (255) DEFAULT (suser_sname()) NULL,
    [UsedOn]      SMALLDATETIME NULL,
    [UsedBy]      VARCHAR (255) NULL,
    CONSTRAINT [PK_Schedules] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [UX_Schedules_Description] UNIQUE NONCLUSTERED ([Description] ASC) WITH (FILLFACTOR = 90)
);

