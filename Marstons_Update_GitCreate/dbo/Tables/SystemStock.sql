CREATE TABLE [dbo].[SystemStock] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [DateIn]           DATETIME       NOT NULL,
    [DateOut]          DATETIME       NULL,
    [OldInstallDate]   DATETIME       NOT NULL,
    [EDISID]           INT            NOT NULL,
    [SystemTypeID]     INT            NOT NULL,
    [CallID]           INT            NOT NULL,
    [PreviousEDISID]   INT            NULL,
    [PreviousName]     VARCHAR (100)  NULL,
    [PreviousPostcode] VARCHAR (25)   NULL,
    [PreviousFMCount]  INT            NULL,
    [WrittenOff]       BIT            DEFAULT (0) NOT NULL,
    [Comment]          VARCHAR (8000) NULL
);

