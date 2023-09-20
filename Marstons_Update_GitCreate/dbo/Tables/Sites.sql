CREATE TABLE [dbo].[Sites] (
    [EDISID]                       INT           IDENTITY (1, 1) NOT NULL,
    [OwnerID]                      INT           NOT NULL,
    [SiteID]                       VARCHAR (15)  NOT NULL,
    [Name]                         VARCHAR (60)  NOT NULL,
    [TenantName]                   VARCHAR (50)  NULL,
    [Address1]                     VARCHAR (50)  NOT NULL,
    [Address2]                     VARCHAR (50)  NULL,
    [Address3]                     VARCHAR (50)  NULL,
    [Address4]                     VARCHAR (50)  NULL,
    [PostCode]                     VARCHAR (8)   NULL,
    [SiteTelNo]                    VARCHAR (30)  NULL,
    [EDISTelNo]                    VARCHAR (512) NOT NULL,
    [EDISPassword]                 VARCHAR (15)  NOT NULL,
    [SiteOnline]                   SMALLDATETIME NOT NULL,
    [SerialNo]                     VARCHAR (255) NULL,
    [Classification]               INT           NULL,
    [Budget]                       FLOAT (53)    NULL,
    [Region]                       INT           NULL,
    [SiteClosed]                   BIT           CONSTRAINT [DF_Sites_SiteClosed] DEFAULT (0) NOT NULL,
    [Version]                      VARCHAR (255) CONSTRAINT [DF_Sites_Version] DEFAULT ('') NULL,
    [LastDownload]                 SMALLDATETIME NULL,
    [Hidden]                       BIT           CONSTRAINT [DF_Sites_Hidden] DEFAULT (0) NOT NULL,
    [Comment]                      TEXT          NULL,
    [IsVRSMember]                  BIT           CONSTRAINT [DF_Sites_IsVRSMember] DEFAULT (0) NOT NULL,
    [ModemTypeID]                  INT           CONSTRAINT [DF_Sites_ModemTypeID] DEFAULT (1) NOT NULL,
    [BDMComment]                   TEXT          NULL,
    [SiteUser]                     VARCHAR (255) DEFAULT ('') NOT NULL,
    [InternalComment]              TEXT          NULL,
    [SystemTypeID]                 INT           CONSTRAINT [SystemTypeID_Default] DEFAULT ((9)) NOT NULL,
    [UpdateID]                     ROWVERSION    NOT NULL,
    [AreaID]                       INT           CONSTRAINT [DF_Sites_AreaID] DEFAULT (1) NOT NULL,
    [SiteGroupID]                  INT           NULL,
    [VRSOwner]                     INT           DEFAULT (1) NOT NULL,
    [CommunicationProviderID]      INT           DEFAULT (1) NOT NULL,
    [OwnershipStatus]              INT           DEFAULT (0) NOT NULL,
    [AltSiteTelNo]                 VARCHAR (30)  NULL,
    [Quality]                      BIT           DEFAULT (0) NOT NULL,
    [InstallationDate]             DATETIME      NULL,
    [GlobalEDISID]                 INT           NULL,
    [Status]                       INT           CONSTRAINT [DF_Sites_Status] DEFAULT ((0)) NOT NULL,
    [ClubMembership]               INT           CONSTRAINT [DF_Sites_ClubMembership] DEFAULT ((0)) NOT NULL,
    [EPOSType]                     INT           DEFAULT ((0)) NOT NULL,
    [LastInstallationDate]         DATETIME      NULL,
    [BirthDate]                    DATETIME      NULL,
    [LastMaintenanceDate]          DATETIME      NULL,
    [LastPATDate]                  DATETIME      NULL,
    [LastElectricalCheckDate]      DATETIME      NULL,
    [LastEPOSImportedDate]         DATETIME      NULL,
    [LastImportedEndDate]          DATETIME      NULL,
    [LastEPOSExceptionProcessDate] DATETIME      NULL,
    CONSTRAINT [PK_Sites] PRIMARY KEY CLUSTERED ([EDISID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Sites_Areas] FOREIGN KEY ([AreaID]) REFERENCES [dbo].[Areas] ([ID]),
    CONSTRAINT [FK_Sites_ModemTypes] FOREIGN KEY ([ModemTypeID]) REFERENCES [dbo].[ModemTypes] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Sites_Owners] FOREIGN KEY ([OwnerID]) REFERENCES [dbo].[Owners] ([ID]),
    CONSTRAINT [FK_Sites_Regions] FOREIGN KEY ([Region]) REFERENCES [dbo].[Regions] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [FK_Sites_SystemTypes] FOREIGN KEY ([SystemTypeID]) REFERENCES [dbo].[SystemTypes] ([ID]) ON DELETE CASCADE,
    CONSTRAINT [UX_Sites_SiteID] UNIQUE NONCLUSTERED ([SiteID] ASC),
    CONSTRAINT [UX_Sites_SiteID_OwnerID] UNIQUE NONCLUSTERED ([OwnerID] ASC, [SiteID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Sites_Hidden_Quality]
    ON [dbo].[Sites]([Hidden] ASC, [Quality] ASC)
    INCLUDE([EDISID]);


GO
CREATE NONCLUSTERED INDEX [IX_Sites_Visibility]
    ON [dbo].[Sites]([Hidden] ASC)
    INCLUDE([EDISID], [SiteID], [Name], [Address3], [Address4], [SiteOnline], [Quality]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This is not the ID of the EDIS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Sites', @level2type = N'COLUMN', @level2name = N'EDISID';

