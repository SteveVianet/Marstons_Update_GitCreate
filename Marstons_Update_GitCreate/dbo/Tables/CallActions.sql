CREATE TABLE [dbo].[CallActions] (
    [ID]         INT            IDENTITY (1, 1) NOT NULL,
    [CallID]     INT            NOT NULL,
    [ActionID]   INT            NOT NULL,
    [ActionUser] VARCHAR (255)  CONSTRAINT [DF_CallActions_ActionUser] DEFAULT (suser_sname()) NOT NULL,
    [ActionTime] DATETIME       CONSTRAINT [DF_CallActions_ActionTime] DEFAULT (getdate()) NOT NULL,
    [ActionText] VARCHAR (2000) NULL,
    CONSTRAINT [PK_CallActions] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CallActions_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);

