CREATE TYPE [dbo].[LocationFilter] AS TABLE (
    [LocationDescription] VARCHAR (100) NOT NULL,
    PRIMARY KEY CLUSTERED ([LocationDescription] ASC));


GO
GRANT CONTROL
    ON TYPE::[dbo].[LocationFilter] TO PUBLIC;

