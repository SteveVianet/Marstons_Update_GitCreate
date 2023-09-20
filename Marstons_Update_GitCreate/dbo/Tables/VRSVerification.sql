CREATE TABLE [dbo].[VRSVerification] (
    [VerificationID]     INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSVerification] PRIMARY KEY CLUSTERED ([VerificationID] ASC)
);

