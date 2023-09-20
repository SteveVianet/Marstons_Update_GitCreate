CREATE TABLE [dbo].[VRSVisitOutcome] (
    [VisitOutcomeID]     INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSVisitOutcome] PRIMARY KEY CLUSTERED ([VisitOutcomeID] ASC)
);

