CREATE PROCEDURE dbo.GetMISSiteTotalDispensed
(
	@ID			INT,
	@From			DATETIME,
	@To			DATETIME,
	@TrendFrom		DATETIME
)
AS

DECLARE @Sites TABLE(EDISID INT NOT NULL)
DECLARE @SiteGroupID INT
DECLARE @SiteOnline  DATETIME
DECLARE @Dispense TABLE([WeekCommencing] DATETIME NOT NULL, Dispensed FLOAT NOT NULL)
DECLARE @AverageDispense FLOAT
DECLARE @TrendDispense FLOAT

SET NOCOUNT ON
SET DATEFIRST 1

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID = @ID

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT @ID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @ID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @ID

INSERT INTO @Dispense
(WeekCommencing, Dispensed)
SELECT DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date]), SUM(Quantity)
FROM dbo.DLData
JOIN dbo.MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN dbo.Sites ON Sites.EDISID = MasterDates.EDISID
WHERE MasterDates.EDISID IN (SELECT EDISID FROM @Sites)
AND MasterDates.[Date] BETWEEN @From AND @To
AND MasterDates.[Date] >= @SiteOnline
GROUP BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])
ORDER BY DATEADD(dw, -DATEPART(dw, MasterDates.[Date]) + 1, MasterDates.[Date])

SELECT @AverageDispense = AVG(Dispensed)
FROM @Dispense

SELECT @TrendDispense = AVG(Dispensed)
FROM @Dispense
WHERE WeekCommencing >= @TrendFrom

SELECT @AverageDispense AS AverageDispense, @TrendDispense AS TrendDispense


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMISSiteTotalDispensed] TO PUBLIC
    AS [dbo];

