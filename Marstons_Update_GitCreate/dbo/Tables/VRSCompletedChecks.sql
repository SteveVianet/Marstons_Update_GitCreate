CREATE TABLE [dbo].[VRSCompletedChecks] (
    [CompletedChecksID]  INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSCompletedChecks] PRIMARY KEY CLUSTERED ([CompletedChecksID] ASC)
);

