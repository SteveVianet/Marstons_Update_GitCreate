CREATE TABLE [dbo].[CleaningProgress] (
    [EDISID]    INT           NOT NULL,
    [Pump]      INT           NOT NULL,
    [Date]      DATETIME      NOT NULL,
    [CleanedBy] VARCHAR (100) NOT NULL,
    [CleanedOn] DATETIME      NOT NULL,
    CONSTRAINT [PK_CleaningProgress] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Pump] ASC, [Date] ASC)
);

