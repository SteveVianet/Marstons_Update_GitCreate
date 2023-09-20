CREATE TABLE [dbo].[VRSTampering] (
    [TamperingID]        INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSTampering] PRIMARY KEY CLUSTERED ([TamperingID] ASC)
);

