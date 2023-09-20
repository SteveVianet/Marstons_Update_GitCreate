CREATE PROCEDURE [dbo].[GetLineCleaningQueue] 

AS

SET DATEFIRST 1
DECLARE @StartOfPreviousWeek DATETIME
DECLARE @EndOfPreviousWeek DATETIME
SET @StartOfPreviousWeek = DATEADD(dd, -DATEPART(dw, GETDATE()), GETDATE()-6)
SET @StartOfPreviousWeek = dbo.DateOnly(@StartOfPreviousWeek)
SET @EndOfPreviousWeek = DATEADD(dd, -DATEPART(dw, GETDATE()), GETDATE())
SET @EndOfPreviousWeek = dbo.DateOnly(@EndOfPreviousWeek)

SELECT Sites.EDISID,
	CASE 
	    WHEN ISNULL(Service.LastAction, @StartOfPreviousWeek) > @StartOfPreviousWeek 
	    THEN Service.LastAction 
	    ELSE @StartOfPreviousWeek 
	END AS FromDate, 
	CASE 
	    WHEN ISNULL(Sites.LastDownload, @EndOfPreviousWeek) < @EndOfPreviousWeek 
	    THEN Sites.LastDownload 
	    ELSE @EndOfPreviousWeek 
	END AS ToDate
FROM Sites
LEFT JOIN (
	SELECT EDISID, Max(Date) AS LastAction
	FROM MasterDates
	JOIN CleaningServiceActions ON MasterDateID = ID
	GROUP BY EDISID
	) As Service
  ON Sites.EDISID = Service.EDISID
WHERE LastDownload >= @StartOfPreviousWeek 
  AND (LastDownload > Service.LastAction OR Service.LastAction IS NULL)
  AND (@EndOfPreviousWeek > Service.LastAction OR Service.LastAction IS NULL)
  --AND (@EndOfPreviousWeek = Service.LastAction OR Service.LastAction IS NULL)
  AND Hidden = 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLineCleaningQueue] TO PUBLIC
    AS [dbo];

