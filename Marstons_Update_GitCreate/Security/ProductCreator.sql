CREATE ROLE [ProductCreator]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'ProductCreator', @membername = N'MAINGROUP\Database Add Product';

