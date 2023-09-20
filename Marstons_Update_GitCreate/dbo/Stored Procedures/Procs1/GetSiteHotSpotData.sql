---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetSiteHotSpotData
(
	@StartDate	DATETIME,
	@EndDate	DATETIME,
	@SiteID	VARCHAR(50)
)

AS

SET DATEFIRST 1

SELECT	SUM(DLData.Quantity) AS Quantity,
		DLData.Shift,
		DATEPART(dw, MasterDates.[Date]) AS [WeekDay]
FROM dbo.Sites
JOIN dbo.MasterDates ON MasterDates.EDISID = Sites.EDISID
JOIN dbo.DLData ON DLData.DownloadID = MasterDates.[ID]
WHERE Sites.SiteID = @SiteID
AND MasterDates.[Date] BETWEEN @StartDate AND @EndDate
AND DLData.Shift BETWEEN 1 AND 24
AND MasterDates.[Date] >= Sites.SiteOnline
GROUP BY DLData.Shift, DATEPART(dw, MasterDates.[Date])

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteHotSpotData] TO PUBLIC
    AS [dbo];

