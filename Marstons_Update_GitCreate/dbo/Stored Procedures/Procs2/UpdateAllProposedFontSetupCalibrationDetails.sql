CREATE PROCEDURE dbo.UpdateAllProposedFontSetupCalibrationDetails
AS

SET NOCOUNT ON

DECLARE curDatabases CURSOR FORWARD_ONLY READ_ONLY FOR
SELECT EDISID, [ID]
FROM ProposedFontSetups

DECLARE @ID		INT
DECLARE @EDISID	INT
DECLARE @SQL		NVARCHAR(1024)
DECLARE @NewGlasswareID INT

OPEN curDatabases
FETCH NEXT FROM curDatabases INTO @EDISID, @ID

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = 'DECLARE @NewGlasswareID INT EXEC dbo.UpdateSiteProposedFontSetupCalibrationDetails ' + CAST(@EDISID AS VARCHAR) + ', ' + CAST(@ID AS VARCHAR) + ', @NewGlasswareID OUTPUT'
	--SET @SQL = 'INSERT INTO #Results EXEC [' + @Server + '].[' + @Database + '].dbo.GetCalibrationMonthSchedule'
	--PRINT @SQL
	EXEC sp_executesql @SQL
	
	FETCH NEXT FROM curDatabases INTO @EDISID, @ID
	
END

CLOSE curDatabases
DEALLOCATE curDatabases

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateAllProposedFontSetupCalibrationDetails] TO PUBLIC
    AS [dbo];

