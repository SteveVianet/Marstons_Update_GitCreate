CREATE PROCEDURE [dbo].[GetSiteGroupTotalProductDispensed]
(
	@SiteGroupID 	INT,
	@ProductID INT,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME
)

AS

SET NOCOUNT ON

DECLARE @MasterDates TABLE([ID] INT NOT NULL, EDISID INT NOT NULL, [Date] DATETIME NOT NULL)

INSERT INTO @MasterDates
([ID], EDISID, [Date])
SELECT MasterDates.[ID], MasterDates.EDISID, [Date]
FROM MasterDates
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
JOIN dbo.SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= Sites.SiteOnline

SELECT SUM(Quantity) AS TotalDispensed
FROM dbo.DLData
JOIN @MasterDates AS MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON MasterDates.EDISID = Sites.EDISID
AND DLData.Product = @ProductID
AND MasterDates.[Date] BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteGroupTotalProductDispensed] TO PUBLIC
    AS [dbo];

