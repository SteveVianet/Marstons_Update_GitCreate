CREATE TABLE [dbo].[TamperCaseEvents] (
    [CaseID]         INT           NOT NULL,
    [EventDate]      DATETIME      NOT NULL,
    [UserID]         INT           NOT NULL,
    [StateID]        INT           NOT NULL,
    [SeverityID]     INT           NOT NULL,
    [TypeListID]     INT           NOT NULL,
    [Text]           VARCHAR (480) NULL,
    [AttachmentsID]  INT           NULL,
    [SeverityUserID] INT           NULL,
    [AcceptedBy]     VARCHAR (100) NULL,
    CONSTRAINT [FK_TamperCaseEvents_InternalUsers] FOREIGN KEY ([UserID]) REFERENCES [dbo].[InternalUsers] ([ID]),
    CONSTRAINT [FK_TamperEvent_Tamper] FOREIGN KEY ([CaseID]) REFERENCES [dbo].[TamperCases] ([CaseID])
);


GO
CREATE CLUSTERED INDEX [IX_TamperCaseEvents_Date]
    ON [dbo].[TamperCaseEvents]([EventDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_TamperCase_State]
    ON [dbo].[TamperCaseEvents]([StateID] ASC)
    INCLUDE([CaseID], [EventDate]);


GO
CREATE NONCLUSTERED INDEX [missing_index_9192_9191_TamperCaseEvents]
    ON [dbo].[TamperCaseEvents]([CaseID] ASC)
    INCLUDE([EventDate], [UserID], [StateID], [SeverityID], [TypeListID], [Text], [AttachmentsID], [SeverityUserID], [AcceptedBy]);

