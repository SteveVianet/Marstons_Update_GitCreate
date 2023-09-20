CREATE TABLE [dbo].[VRSFurtherAction] (
    [FurtherActionID]    INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSFurtherAction] PRIMARY KEY CLUSTERED ([FurtherActionID] ASC)
);

