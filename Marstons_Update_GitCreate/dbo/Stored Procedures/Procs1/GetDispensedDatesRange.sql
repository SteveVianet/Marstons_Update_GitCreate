CREATE PROCEDURE [dbo].[GetDispensedDatesRange]
(
      @EDISID           INT
)
AS

SELECT MasterDates.EDISID, MAX([Date]) AS MaxDate, MIN([Date]) AS MinDate
FROM MasterDates 
JOIN DLData
  ON DLData.DownloadID = MasterDates.ID
WHERE MasterDates.EDISID = @EDISID
GROUP BY MasterDates.EDISID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDispensedDatesRange] TO PUBLIC
    AS [dbo];

