CREATE PROCEDURE [dbo].[GetDailyCleaningAndDispenseReport]
(
	@From	DATETIME = NULL,
	@To		DATETIME = NULL
)
AS

SET NOCOUNT ON

DECLARE @Month			INT
DECLARE @Year			INT

CREATE TABLE #ValidMasterDates	([ID] INT NOT NULL PRIMARY KEY)
CREATE TABLE #Cleans 			(MasterDateID INT NOT NULL PRIMARY KEY)

SET @Month = MONTH(@From) 
SET @Year = YEAR(@From)

INSERT INTO #ValidMasterDates
([ID])
SELECT ID
FROM dbo.MasterDates
WHERE [Date] BETWEEN @From AND @To

INSERT INTO #Cleans
(MasterDateID)
SELECT MasterDates.[ID]
FROM dbo.WaterStack AS WaterStack
JOIN dbo.MasterDates AS MasterDates  WITH (NOLOCK) ON MasterDates.ID = WaterStack.WaterID
JOIN #ValidMasterDates AS VMD ON VMD.ID = MasterDates.ID
WHERE WaterStack.Volume >= 4
GROUP BY MasterDates.[ID]

SELECT  SiteID,
	Products.[Description],
	MasterDates.[Date],
	SUM(DLData.Quantity),
	CAST(CASE WHEN Cleans.MasterDateID IS NULL THEN 0 ELSE 1 END AS BIT)
FROM dbo.DLData AS DLData WITH (NOLOCK)
JOIN dbo.MasterDates AS MasterDates WITH (NOLOCK) ON MasterDates.ID = DLData.DownloadID
JOIN #ValidMasterDates AS VMD ON VMD.ID = MasterDates.ID
JOIN dbo.Products AS Products WITH (NOLOCK) ON Products.ID = DLData.Product
JOIN dbo.Sites AS Sites WITH (NOLOCK) ON Sites.EDISID = MasterDates.EDISID
LEFT JOIN #Cleans AS Cleans ON (Cleans.MasterDateID = MasterDates.[ID])
WHERE Sites.Hidden = 0
GROUP BY SiteID, Products.[Description], MasterDates.[Date], Cleans.MasterDateID

DROP TABLE #ValidMasterDates
DROP TABLE #Cleans

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDailyCleaningAndDispenseReport] TO PUBLIC
    AS [dbo];

