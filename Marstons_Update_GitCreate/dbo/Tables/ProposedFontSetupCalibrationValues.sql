CREATE TABLE [dbo].[ProposedFontSetupCalibrationValues] (
    [ProposedFontSetupID] INT        NOT NULL,
    [FontNumber]          INT        NOT NULL,
    [Reading]             INT        NOT NULL,
    [zzzValue]            FLOAT (53) NULL,
    [Pulses]              INT        CONSTRAINT [DF_ProposedFontSetupCalibrationValues_Pulses] DEFAULT (0) NOT NULL,
    [Volume]              FLOAT (53) CONSTRAINT [DF_ProposedFontSetupCalibrationValues_Volume] DEFAULT (284.130625) NOT NULL,
    [Selected]            BIT        CONSTRAINT [DF_ProposedFontSetupCalibrationValues_Selected] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_ProposedFontSetupCalibrationValues] PRIMARY KEY CLUSTERED ([ProposedFontSetupID] ASC, [FontNumber] ASC, [Reading] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ProposedFontSetupCalibrationValues_ProposedFontSetupItems] FOREIGN KEY ([ProposedFontSetupID], [FontNumber]) REFERENCES [dbo].[ProposedFontSetupItems] ([ProposedFontSetupID], [FontNumber])
);

