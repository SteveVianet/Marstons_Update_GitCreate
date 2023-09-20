CREATE TABLE [dbo].[VRSAdmission] (
    [AdmissionID]        INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSAdmission] PRIMARY KEY CLUSTERED ([AdmissionID] ASC)
);

