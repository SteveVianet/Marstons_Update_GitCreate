CREATE TABLE [dbo].[SiteExceptionEmailAddresses] (
    [EDISID] INT           NOT NULL,
    [Email]  VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_SiteExceptionEmailAddresses] PRIMARY KEY CLUSTERED ([EDISID] ASC, [Email] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_SiteExceptionEmailAddresses_Sites] FOREIGN KEY ([EDISID]) REFERENCES [dbo].[Sites] ([EDISID])
);

