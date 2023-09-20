CREATE TABLE [dbo].[DownloadReports] (
    [EDISID]       INT           NOT NULL,
    [DownloadedOn] DATETIME      NOT NULL,
    [ReportText]   VARCHAR (100) NOT NULL,
    [IsError]      BIT           NOT NULL,
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_DownloadReports] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_DownloadReports_EDISID_DownloadedOn]
    ON [dbo].[DownloadReports]([EDISID] ASC, [DownloadedOn] ASC);

