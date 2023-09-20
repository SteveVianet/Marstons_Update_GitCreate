EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'MAINGROUP\Full Database ReadWrite Access';


GO
EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'eposimport';


GO
EXECUTE sp_addrolemember @rolename = N'db_ddladmin', @membername = N'MAINGROUP\Auditmaintenance';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\Full Database ReadOnly Access';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\Brulines.SQL1';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\PDFReports';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\CoinMetrics.SQL1';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'NewSystemLogin';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\SQLE.MIS01';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'testdb.import';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'S.Beddow';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'migrationuserRO';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'MAINGROUP\Auditmaintenance';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'dean.grimm';


GO
EXECUTE sp_addrolemember @rolename = N'db_datawriter', @membername = N'MAINGROUP\PDFReports';


GO
EXECUTE sp_addrolemember @rolename = N'db_datawriter', @membername = N'MAINGROUP\Auditmaintenance';

