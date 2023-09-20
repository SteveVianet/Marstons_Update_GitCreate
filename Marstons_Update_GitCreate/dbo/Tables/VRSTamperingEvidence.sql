CREATE TABLE [dbo].[VRSTamperingEvidence] (
    [TamperingEvidenceID] INT NOT NULL,
    [Depricated]          BIT NOT NULL,
    [EscalateToUserType]  INT NULL,
    CONSTRAINT [PK_VRSTamperingEvidence] PRIMARY KEY CLUSTERED ([TamperingEvidenceID] ASC)
);

