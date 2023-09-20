CREATE TABLE [dbo].[ErrorLogs] (
    [DateStamp]        SMALLDATETIME  CONSTRAINT [DF_ErrorLogs_DateStamp] DEFAULT (getdate()) NOT NULL,
    [UserName]         VARCHAR (255)  NOT NULL,
    [ErrorNumber]      INT            NOT NULL,
    [ErrorDescription] VARCHAR (1024) NOT NULL,
    [ErrorSource]      VARCHAR (255)  NOT NULL,
    [MethodName]       VARCHAR (255)  NOT NULL
);


GO
CREATE CLUSTERED INDEX [IX_ErrorLogs_DateStamp]
    ON [dbo].[ErrorLogs]([DateStamp] ASC);

