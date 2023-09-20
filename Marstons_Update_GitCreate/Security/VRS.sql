CREATE ROLE [VRS]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'VRS', @membername = N'MAINGROUP\VRS';

