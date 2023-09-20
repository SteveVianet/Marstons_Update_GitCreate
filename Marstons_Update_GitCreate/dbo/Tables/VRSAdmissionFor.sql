CREATE TABLE [dbo].[VRSAdmissionFor] (
    [AdmissionForID]     INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSAdmissionFor] PRIMARY KEY CLUSTERED ([AdmissionForID] ASC)
);

