CREATE TABLE [dbo].[VRSJobTitle] (
    [JobTitleID]         INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSJobTitle] PRIMARY KEY CLUSTERED ([JobTitleID] ASC)
);

