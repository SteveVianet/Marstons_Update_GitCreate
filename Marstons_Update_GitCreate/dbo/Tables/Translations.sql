CREATE TABLE [dbo].[Translations] (
    [ActualName]     VARCHAR (256) NOT NULL,
    [TranslatedName] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_Translations] PRIMARY KEY CLUSTERED ([ActualName] ASC) WITH (FILLFACTOR = 90)
);

