CREATE TABLE [dbo].[VRSSpecificOutcome] (
    [SpecificOutcomeID]  INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSSpecificOutcome] PRIMARY KEY CLUSTERED ([SpecificOutcomeID] ASC)
);

