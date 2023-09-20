CREATE PROCEDURE [dbo].[GetImportedFileDates]
(
	@FileID						INT = 0
)

AS

DECLARE @StartDate AS DATETIME
DECLARE @EndDate AS DATETIME

SET @FileID = 2

SET @StartDate = 
	(SELECT MasterDates.Date FROM Delivery
	 JOIN MasterDates ON MasterDates.ID = Delivery.DeliveryID
	 WHERE Delivery.ID = (SELECT StartID FROM ImportedFiles WHERE ID = @FileID))

SET @EndDate = 
	(SELECT MasterDates.Date FROM Delivery
	 JOIN MasterDates ON MasterDates.ID = Delivery.DeliveryID
	 WHERE Delivery.ID = (SELECT EndID FROM ImportedFiles WHERE ID = @FileID))

SELECT @StartDate AS StartDate, @EndDate AS EndDate