---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetWaterDispensedByUser
(
	@UserID	INT,
	@From	DATETIME,
	@To	DATETIME
)

AS

DECLARE @AllSitesVisible	BIT

SELECT @AllSitesVisible = AllSitesVisible
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

IF @AllSitesVisible = 1
BEGIN
	SELECT	Sites.EDISID,
		MasterDates.[Date],
		SUM(DLData.Quantity) AS Quantity
	FROM Sites
	JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
	JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
	JOIN Products ON Products.[ID] = DLData.Product
	WHERE MasterDates.[Date] BETWEEN @From AND @To
	AND Products.IsWater = 1
	GROUP BY Sites.EDISID, MasterDates.[Date]
END
ELSE
BEGIN
	SELECT	UserSites.EDISID,
		MasterDates.[Date],
		SUM(DLData.Quantity) AS Quantity
	FROM UserSites
	JOIN MasterDates ON MasterDates.EDISID = UserSites.EDISID
	JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
	JOIN Products ON Products.[ID] = DLData.Product
	WHERE UserSites.UserID = @UserID
	AND MasterDates.[Date] BETWEEN @From AND @To
	AND Products.IsWater = 1
	GROUP BY UserSites.EDISID, MasterDates.[Date]
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWaterDispensedByUser] TO PUBLIC
    AS [dbo];

