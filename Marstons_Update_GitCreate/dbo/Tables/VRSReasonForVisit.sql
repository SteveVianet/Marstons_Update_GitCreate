CREATE TABLE [dbo].[VRSReasonForVisit] (
    [ReasonID]           INT NOT NULL,
    [Depricated]         BIT CONSTRAINT [DF_VRSReasonForVisit_Depricated] DEFAULT (0) NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSReasonForVisit] PRIMARY KEY CLUSTERED ([ReasonID] ASC)
);

