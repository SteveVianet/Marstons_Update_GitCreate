CREATE ROLE [SiteCreator]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'SiteCreator', @membername = N'MAINGROUP\Installation Loaders';


GO
EXECUTE sp_addrolemember @rolename = N'SiteCreator', @membername = N'MAINGROUP\Database Add Site';

