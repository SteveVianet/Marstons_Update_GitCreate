CREATE TABLE [dbo].[SiteExceptions] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [EDISID]                INT            NOT NULL,
    [Type]                  VARCHAR (100)  NOT NULL,
    [TradingDate]           DATE           NOT NULL,
    [Value]                 FLOAT (53)     NOT NULL,
    [LowThreshold]          FLOAT (53)     NULL,
    [HighThreshold]         FLOAT (53)     NULL,
    [ShiftStart]            DATETIME       NULL,
    [ShiftEnd]              DATETIME       NULL,
    [ExceptionEmailID]      INT            NULL,
    [AdditionalInformation] VARCHAR (MAX)  NULL,
    [ExceptionHTML]         VARCHAR (MAX)  NULL,
    [SiteDescription]       VARCHAR (1000) NULL,
    [DateFormat]            VARCHAR (25)   NULL,
    [EmailReplyTo]          VARCHAR (50)   NULL,
    [TypeID]                INT            NULL,
    CONSTRAINT [PK_SiteExceptions] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_SiteExceptions_Emails] FOREIGN KEY ([ExceptionEmailID]) REFERENCES [dbo].[SiteExceptionEmails] ([ID]),
    CONSTRAINT [FK_SiteExceptions_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);


GO
CREATE NONCLUSTERED INDEX [IX_SiteExceptions]
    ON [dbo].[SiteExceptions]([EDISID] ASC, [TradingDate] ASC);

