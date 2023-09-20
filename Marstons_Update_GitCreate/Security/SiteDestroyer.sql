CREATE ROLE [SiteDestroyer]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'SiteDestroyer', @membername = N'MAINGROUP\Database Delete Site';

