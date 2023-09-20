CREATE PROCEDURE dbo.GetSiteDispenseDateSummary
(
	@EDISID 	INT
)
AS

SELECT MIN(MasterDates.Date) AS EarliestDispenseDate, MAX(MasterDates.Date) AS LatestDispenseDate
FROM DLData
JOIN MasterDates ON MasterDates.ID = DLData.DownloadID
WHERE MasterDates.EDISID = @EDISID

