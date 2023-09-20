CREATE PROCEDURE [dbo].[GetSiteLocations]
(
	@EDISID	INT
)

AS

SET NOCOUNT ON

CREATE TABLE #Locations ([ID] INT NOT NULL, [Name] VARCHAR(255), [GlobalID] INT)

INSERT INTO #Locations ([ID])
SELECT DISTINCT LocationID
FROM dbo.PumpSetup AS PumpSetup
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT LocationID
FROM dbo.Calibrations AS Calibrations
WHERE EDISID = @EDISID
UNION
SELECT DISTINCT LocationID
FROM dbo.EquipmentReadings AS EquipmentReadings
WHERE EDISID = @EDISID

UPDATE #Locations
SET [Name] = Locations.[Description],
	[GlobalID] = Locations.[GlobalID]
FROM dbo.Locations AS Locations
JOIN #Locations ON #Locations.ID =  Locations.ID

SELECT [ID], [Name] AS Description, [GlobalID]
FROM #Locations
ORDER BY [ID]

DROP TABLE #Locations

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLocations] TO PUBLIC
    AS [dbo];

