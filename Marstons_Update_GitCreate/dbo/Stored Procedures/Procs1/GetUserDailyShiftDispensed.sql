---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE dbo.GetUserDailyShiftDispensed
(
	@UserID		INT,
	@From		DATETIME,
	@To		DATETIME,
	@ProductID	INTEGER	= NULL
)

AS

SELECT  MasterDates.[Date], 
	DLData.Shift,
	SUM(Quantity) AS Quantity
FROM dbo.UserSites
JOIN dbo.MasterDates ON MasterDates.EDISID = UserSites.EDISID
JOIN dbo.DLData ON DLData.DownloadID = MasterDates.[ID]
JOIN dbo.Sites ON Sites.EDISID = UserSites.EDISID
WHERE UserSites.UserID = @UserID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline
AND (@ProductID IS NULL OR DLData.Product = @ProductID)
GROUP BY MasterDates.[Date], DLData.Shift




GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserDailyShiftDispensed] TO PUBLIC
    AS [dbo];

