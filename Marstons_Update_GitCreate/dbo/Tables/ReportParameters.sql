CREATE TABLE [dbo].[ReportParameters] (
    [EDISID]         INT           NOT NULL,
    [ReportID]       INT           NOT NULL,
    [ParameterID]    INT           NOT NULL,
    [ParameterValue] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_ReportParameters] PRIMARY KEY CLUSTERED ([EDISID] ASC, [ReportID] ASC, [ParameterID] ASC)
);

