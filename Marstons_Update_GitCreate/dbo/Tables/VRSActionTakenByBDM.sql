CREATE TABLE [dbo].[VRSActionTakenByBDM] (
    [ActionTakenID] INT NOT NULL,
    [Depricated]    BIT CONSTRAINT [DF_VRSActionTakenByBDM_Depricated] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_VRSActionTakenByBDM] PRIMARY KEY CLUSTERED ([ActionTakenID] ASC)
);

