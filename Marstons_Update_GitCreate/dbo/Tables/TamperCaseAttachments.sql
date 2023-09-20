CREATE TABLE [dbo].[TamperCaseAttachments] (
    [AttachmentID]   INT           NOT NULL,
    [AttachmentName] VARCHAR (124) NOT NULL,
    CONSTRAINT [PK_TamperCaseAttachments] PRIMARY KEY CLUSTERED ([AttachmentID] ASC)
);

