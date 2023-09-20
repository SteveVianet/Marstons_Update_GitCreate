CREATE ROLE [TeamLeader]
    AUTHORIZATION [dbo];


GO
EXECUTE sp_addrolemember @rolename = N'TeamLeader', @membername = N'MAINGROUP\Calibrators';


GO
EXECUTE sp_addrolemember @rolename = N'TeamLeader', @membername = N'MAINGROUP\Data Management Team Leaders';


GO
EXECUTE sp_addrolemember @rolename = N'TeamLeader', @membername = N'MAINGROUP\Team Leaders';

