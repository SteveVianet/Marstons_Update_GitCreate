CREATE TABLE [dbo].[ImportedFileLogDetail] (
    [ImportedFileLogID] INT            NOT NULL,
    [FileNumber]        INT            NOT NULL,
    [Success]           BIT            NOT NULL,
    [Details]           VARCHAR (4000) NOT NULL
);

