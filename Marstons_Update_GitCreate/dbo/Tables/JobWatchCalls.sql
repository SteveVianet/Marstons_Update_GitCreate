CREATE TABLE [dbo].[JobWatchCalls] (
    [ID]                     INT             IDENTITY (1, 1) NOT NULL,
    [EdisID]                 INT             NOT NULL,
    [CallID]                 INT             NOT NULL,
    [JobId]                  INT             NULL,
    [JobReference]           NVARCHAR (40)   NULL,
    [JobType]                NVARCHAR (100)  NOT NULL,
    [OriginalJobDescription] NVARCHAR (4000) NOT NULL,
    [CurrentJobDescription]  NVARCHAR (500)  NULL,
    [EngineerName]           VARCHAR (255)   NOT NULL,
    [ResourceName]           NVARCHAR (50)   NULL,
    [StatusId]               INT             CONSTRAINT [DF_JobWatchCalls_StatusId] DEFAULT ((0)) NOT NULL,
    [StatusName]             NVARCHAR (100)  NULL,
    [StatusLastChanged]      DATETIME        NULL,
    [JobActive]              BIT             CONSTRAINT [DF_JobWatchCalls_JobActive] DEFAULT ((1)) NOT NULL,
    [PreRelease]             BIT             CONSTRAINT [DF_JobWatchCalls_PreRelease] DEFAULT ((0)) NOT NULL,
    [AwaitPO]                BIT             NOT NULL,
    [Invalid]                BIT             NOT NULL,
    [Posted]                 BIT             NOT NULL,
    [PostResults]            NVARCHAR (200)  NOT NULL,
    [RequestedBy]            VARCHAR (256)   NULL,
    [CreatedOn]              DATETIME        CONSTRAINT [DF_JobWatchCalls_CreatedOn] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_JobWatchCalls_1] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[JobWatchCalls] TO [fusion]
    AS [dbo];

