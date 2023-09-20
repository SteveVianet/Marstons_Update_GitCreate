CREATE TABLE [dbo].[SupplementaryCallStatusItems] (
    [ID]                        INT            IDENTITY (1, 1) NOT NULL,
    [CallID]                    INT            NOT NULL,
    [SupplementaryCallStatusID] INT            NOT NULL,
    [SupplementaryDate]         DATETIME       NULL,
    [SupplementaryText]         VARCHAR (1024) NULL,
    [ChangedOn]                 DATETIME       DEFAULT (getdate()) NOT NULL,
    [ChangedBy]                 VARCHAR (255)  DEFAULT (suser_sname()) NOT NULL,
    CONSTRAINT [PK_SupplementaryCallStatusItems] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SupplementaryCallStatusItems_Calls] FOREIGN KEY ([CallID]) REFERENCES [dbo].[Calls] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_SupplementaryCallStatusItems_CallID_ID_Date_Text]
    ON [dbo].[SupplementaryCallStatusItems]([CallID] ASC)
    INCLUDE([ID], [SupplementaryCallStatusID], [SupplementaryDate], [SupplementaryText]);

