CREATE PROCEDURE [dbo].[CreateNewCustomerDatabase]
(
	@MasterServer			VARCHAR(50),
	@TargetServer			VARCHAR(50),
	@NewDatabaseName		VARCHAR(255),
	@NewCompanyName			VARCHAR(255),
	@NewShortCompanyName	VARCHAR(20),
	@IsEnabled				BIT,
	@IsDevelopment			BIT
)
AS

/*
SET @MasterServer		= 'SQL1\SQL1'
SET @TargetServer		= 'EDISSQL2'
SET @NewDatabaseName	= 'Fortney'
SET @NewCompanyName		= 'Fortney Companies'
SET @NewShortCompanyName = 'FC'
SET @IsEnabled			= 1
SET @IsDevelopment		= 0
*/

DECLARE @NewDataFile VARCHAR(255)
DECLARE @NewLogFile VARCHAR(255)
DECLARE @SQL VARCHAR(8000)

DECLARE @DataDrive CHAR(1)
DECLARE @LogDrive CHAR(1)

--USE master

-- Detect the default DATA and LOG locations
-- 2008R2 doesn't support native methods and must instead access the registry
-- https://stackoverflow.com/questions/1883071/how-do-i-find-the-data-directory-for-a-sql-server-instance/12756990#12756990
declare @DefaultData nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData output

declare @DefaultLog nvarchar(512)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog output

SELECT 
    @DataDrive = LEFT(@DefaultData, 1), 
    @LogDrive = LEFT(@DefaultLog, 1)

-- Set up the file backup device
EXEC sp_addumpdevice 'disk', 'EmptyDatabase_BackupDevice', 'C:\SQLBackup\EmptyDatabase.bak'

-- Back up the full MyNwind database.
BACKUP DATABASE EmptyDatabase
TO EmptyDatabase_BackupDevice
WITH INIT

-- Name the actual files used for the data & logs
SET @NewDataFile = @DataDrive+':\Data\'+@NewDatabaseName+'.mdf'
SET @NewLogFile = @LogDrive+':\Logs\'+@NewDatabaseName+'_1.ldf'

-- Restore the backup of EmptyDatabase using the new customer information
RESTORE DATABASE @NewDatabaseName
FROM EmptyDatabase_BackupDevice
WITH
	MOVE 'EDIS_Data' TO @NewDataFile,
	MOVE 'EDIS_Log' TO @NewLogFile

-- Remove the backup device we just created
EXEC sp_dropdevice 'EmptyDatabase_BackupDevice'

-- Update the default owner to match the customer name supplied
SET @SQL = 'UPDATE ['+@NewDatabaseName+'].dbo.Owners SET [Name] = '''+@NewCompanyName+''''
EXEC(@SQL)

-- Register the new database for the EDIS software
SET @SQL = 'INSERT INTO ['+@MasterServer+'].ServiceLogger.dbo.EDISDatabases (Server, [Name], CompanyName, [Enabled], IsDevelopment, DownloadService, DownloadPriority, MultipleAuditors, ShortCompanyName) VALUES (''' +@TargetServer+ ''', '''+@NewDatabaseName+''', '''+@NewCompanyName+''', '+CAST(@IsEnabled AS VARCHAR)+', '+CAST(@IsDevelopment AS VARCHAR)+', 1, 3, 0, '''+@NewShortCompanyName+''')'
EXEC(@SQL)

-- Update the local owner ID
SET @SQL = 'INSERT INTO ['+@NewDatabaseName+'].dbo.Configuration (PropertyName, PropertyValue) SELECT ''Service Owner ID'', CAST([ID] AS VARCHAR) FROM ['+@MasterServer+'].ServiceLogger.dbo.EDISDatabases WHERE [Name] = '''+@NewDatabaseName+''''
EXEC(@SQL)

-- Update the company name
SET @SQL = 'UPDATE ['+@NewDatabaseName+'].dbo.Configuration SET [PropertyValue] = '''+@NewCompanyName+''' WHERE PropertyName = ''Company Name'''
EXEC(@SQL)

-- Allow multi-user access to new DB
SET @SQL = 'ALTER DATABASE '+@NewDatabaseName+' SET MULTI_USER'
EXEC(@SQL)
