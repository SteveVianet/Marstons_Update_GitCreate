CREATE PROCEDURE dbo.AddCleaningServiceAction 
(
	@EDISID 	INTEGER, 
	@Date		DATETIME
)
AS


DECLARE @DownloadID	INTEGER

EXEC AddDelDispDate @EDISID, @Date

--Check delivery date does not already exist
SELECT @DownloadID = [ID]
FROM dbo.MasterDates
WHERE EDISID = @EDISID
AND [Date] = @Date


INSERT INTO CleaningServiceActions (MasterDateID) 
VALUES (@DownloadID)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCleaningServiceAction] TO PUBLIC
    AS [dbo];

