CREATE ROLE [ProductDestroyer]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'ProductDestroyer', @membername = N'MAINGROUP\Database Delete Product';

