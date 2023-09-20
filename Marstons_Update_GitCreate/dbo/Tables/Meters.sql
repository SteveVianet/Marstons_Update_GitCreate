CREATE TABLE [dbo].[Meters] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [EDISID]          INT           NOT NULL,
    [DigitID]         INT           NOT NULL,
    [TextID]          VARCHAR (255) NOT NULL,
    [ModemSerial]     VARCHAR (255) NOT NULL,
    [IMEI]            VARCHAR (25)  NOT NULL,
    [FirmwareVersion] VARCHAR (25)  NOT NULL,
    CONSTRAINT [PK_Meters] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Meters_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID]) ON DELETE CASCADE
);

