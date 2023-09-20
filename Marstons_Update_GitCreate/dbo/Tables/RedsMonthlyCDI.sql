CREATE TABLE [dbo].[RedsMonthlyCDI] (
    [DatabaseID]  INT          NOT NULL,
    [MonthNumber] INT          NOT NULL,
    [Month]       VARCHAR (50) NOT NULL,
    [Year]        INT          NOT NULL,
    [FromMonday]  DATETIME     NOT NULL,
    [ToMonday]    DATETIME     NOT NULL,
    [CDI]         FLOAT (53)   NOT NULL
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[RedsMonthlyCDI] TO PUBLIC
    AS [dbo];

