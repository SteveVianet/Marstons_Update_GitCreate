CREATE TABLE [dbo].[VRSCalChecksCompleted] (
    [CalChecksCompletedID] INT NOT NULL,
    [Depricated]           BIT NOT NULL,
    [EscalateToUserType]   INT NULL,
    CONSTRAINT [PK_VRSCalChecksCompleted] PRIMARY KEY CLUSTERED ([CalChecksCompletedID] ASC)
);

