CREATE TABLE [dbo].[VRSAdmissionReason] (
    [AdmissionReasonID]  INT NOT NULL,
    [Depricated]         BIT NOT NULL,
    [EscalateToUserType] INT NULL,
    CONSTRAINT [PK_VRSAdmissionReason] PRIMARY KEY CLUSTERED ([AdmissionReasonID] ASC)
);

