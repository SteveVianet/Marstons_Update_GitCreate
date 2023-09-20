CREATE ROLE [WebAdmin]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'WebAdmin', @membername = N'MAINGROUP\Data Management Team Leaders';


GO
EXECUTE sp_addrolemember @rolename = N'WebAdmin', @membername = N'MAINGROUP\Installation Loaders';


GO
EXECUTE sp_addrolemember @rolename = N'WebAdmin', @membername = N'MAINGROUP\Database Web Administration';

