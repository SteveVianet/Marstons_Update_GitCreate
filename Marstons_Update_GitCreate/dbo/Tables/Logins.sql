CREATE TABLE [dbo].[Logins] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [Login]     VARCHAR (255) NOT NULL,
    [SuperUser] BIT           NOT NULL
);

