CREATE TABLE [dbo].[OwnerUserTypePermissions] (
    [OwnerID]                     INT        NOT NULL,
    [UserTypeID]                  INT        NOT NULL,
    [CanEditAlarms]               BIT        NOT NULL,
    [CanEditExceptionThresholds]  FLOAT (53) NOT NULL,
    [CanEditExceptionDelivery]    FLOAT (53) NOT NULL,
    [CanEditExceptionIsKeyValues] FLOAT (53) NOT NULL,
    CONSTRAINT [PK_OwnerUserTypePermissions] PRIMARY KEY CLUSTERED ([OwnerID] ASC, [UserTypeID] ASC),
    CONSTRAINT [FK_OwnerUserTypePermissions_Owners] FOREIGN KEY ([OwnerID]) REFERENCES [dbo].[Owners] ([ID]),
    CONSTRAINT [FK_OwnerUserTypePermissions_Products] FOREIGN KEY ([UserTypeID]) REFERENCES [dbo].[UserTypes] ([ID])
);

