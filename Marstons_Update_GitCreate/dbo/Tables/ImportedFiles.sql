CREATE TABLE [dbo].[ImportedFiles] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [FileName]    VARCHAR (255) NOT NULL,
    [ImportedBy]  VARCHAR (255) CONSTRAINT [DF_ImportedFiles_ImportedBy] DEFAULT (suser_sname()) NOT NULL,
    [ImportDate]  DATETIME      CONSTRAINT [DF_ImportedFiles_ImportDate] DEFAULT (getdate()) NOT NULL,
    [Type]        INT           NOT NULL,
    [StartID]     INT           NOT NULL,
    [EndID]       INT           NOT NULL,
    [Deleted]     BIT           CONSTRAINT [DF_ImportedFiles_Deleted] DEFAULT (0) NOT NULL,
    [DeletedBy]   VARCHAR (255) NULL,
    [DeletedDate] DATETIME      NULL,
    [GUID]        CHAR (36)     CONSTRAINT [DF_ImportedFiles_GUID] DEFAULT (newid()) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_ImportedFiles_ID]
    ON [dbo].[ImportedFiles]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ImportedFiles_GUID]
    ON [dbo].[ImportedFiles]([GUID] ASC);

