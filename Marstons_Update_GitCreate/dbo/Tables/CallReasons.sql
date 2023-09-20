CREATE TABLE [dbo].[CallReasons] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [CallID]         INT           NOT NULL,
    [AdditionalInfo] VARCHAR (512) NULL,
    [ReasonTypeID]   INT           NOT NULL,
    CONSTRAINT [PK_CallReasons] PRIMARY KEY CLUSTERED ([ID] ASC)
);

