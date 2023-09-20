CREATE PROCEDURE [dbo].[GetImportedFiles]

AS

SET NOCOUNT ON 

DECLARE curFiles CURSOR FORWARD_ONLY READ_ONLY FOR
	SELECT [ID]
	FROM dbo.ImportedFiles
	ORDER BY [ID]

DECLARE @ID AS INT
DECLARE @StartDate AS DATETIME
DECLARE @EndDate AS DATETIME

Create Table #Files (	[FileID] INT,
						[FileName] NVARCHAR(255),
						[ImportedBy] NVARCHAR(255),
						[ImportDate] DATETIME,
						[Type] INT,
						[StartID] INT,
						[EndID] INT,
						[Deleted] BIT,
						[DeletedBy] NVARCHAR(255),
						[DeletedDate] DATETIME,
						[StartDate] DATETIME,
						[EndDate] DATETIME)

Create Nonclustered Index ix_temp_index ON #Files (FileID)

--Open cursor and get first row
OPEN curFiles
FETCH NEXT FROM curFiles INTO @ID


WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #Files
	(FileID, [FileName], ImportedBy, ImportDate, [Type], StartID, EndID, Deleted, DeletedBy, DeletedDate)
	SELECT	[ID], [FileName], [ImportedBy], [ImportDate], [Type], [StartID], [EndID], [Deleted], [DeletedBy], [DeletedDate]
	FROM dbo.ImportedFiles WHERE ID = @ID
	
	UPDATE #Files
	SET StartDate = (SELECT MasterDates.Date FROM Delivery
					 JOIN MasterDates ON MasterDates.ID = Delivery.DeliveryID
					 WHERE Delivery.ID = (SELECT StartID FROM ImportedFiles WHERE ID = @ID))
	WHERE FileID = @ID
	
	UPDATE #Files
	SET EndDate = (SELECT MasterDates.Date FROM Delivery
				   JOIN MasterDates ON MasterDates.ID = Delivery.DeliveryID
				   WHERE Delivery.ID = (SELECT EndID FROM ImportedFiles WHERE ID = @ID))
	WHERE FileID = @ID

	--Get next row
	FETCH NEXT FROM curFiles INTO @ID
END

SELECT [FileID] AS ID, [FileName], [ImportedBy], [ImportDate], [Type], [StartID], [EndID], [Deleted], [DeletedBy], [DeletedDate], [StartDate], [EndDate]
FROM #Files

--Clean up
CLOSE curFiles
DEALLOCATE curFiles
DROP TABLE #Files
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetImportedFiles] TO PUBLIC
    AS [dbo];

