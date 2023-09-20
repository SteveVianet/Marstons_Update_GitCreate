CREATE TABLE [dbo].[VRSAccessDetail] (
    [AccessDetailID]     INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSAccessDetail] PRIMARY KEY CLUSTERED ([AccessDetailID] ASC)
);

