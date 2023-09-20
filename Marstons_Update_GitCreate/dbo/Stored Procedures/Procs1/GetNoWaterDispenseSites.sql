CREATE PROCEDURE dbo.[GetNoWaterDispenseSites]
(
	@From		DATETIME,
	@To		DATETIME
)
AS

SET NOCOUNT ON

SELECT Configuration.PropertyValue AS Customer, 
	 Sites.SiteID, 
	 Sites.Name, 
	 Sites.PostCode, 
	 CASE Sites.SiteClosed WHEN 1 THEN 'Yes' ELSE 'No' END AS Closed, 
	 COUNT(ISNULL(WaterDispense.Volume, 0)) AS Volume
FROM Sites
FULL JOIN 
		(SELECT EDISID, Volume FROM
		(SELECT Sites.EDISID, COUNT(Volume) AS Volume
		FROM Sites
		FULL JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
		FULL JOIN WaterStack ON WaterStack.WaterID = MasterDates.[ID]
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND Sites.Quality = 0
		AND Sites.Hidden = 0
		GROUP BY Sites.EDISID) AS Stack

		UNION SELECT * FROM
		(SELECT Sites.EDISID, COUNT(Pints) AS Volume
		FROM Sites
		JOIN 
			(SELECT EDISID, COUNT(Pints) AS Pints FROM DispenseActions WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @From AND @To AND DispenseActions.LiquidType = 1 GROUP BY DispenseActions.EDISID) AS Dispense
		ON Dispense.EDISID = Sites.EDISID
		WHERE Sites.Quality = 1
		AND Sites.Hidden = 0
		GROUP BY Sites.EDISID) AS Actions

		UNION SELECT * FROM
		(SELECT Sites.EDISID, COUNT(Quantity) AS Volume
		FROM Sites
		FULL JOIN MasterDates ON MasterDates.EDISID = Sites.EDISID
		FULL JOIN DLData ON DLData.DownloadID = MasterDates.[ID]
		FULL JOIN Products ON Products.[ID] = DLData.Product
		WHERE MasterDates.[Date] BETWEEN @From AND @To
		AND Products.IsWater = 1
		AND Sites.Hidden = 0
		GROUP BY Sites.EDISID) AS DL) 

AS WaterDispense ON WaterDispense.EDISID = Sites.EDISID
JOIN Configuration ON Configuration.PropertyName = 'Company Name'
WHERE Sites.Hidden = 0
AND (WaterDispense.Volume = 0 OR WaterDispense.Volume IS NULL)
GROUP BY Configuration.PropertyValue, 
	      Sites.SiteID, 
	      Sites.Name, 
	      Sites.PostCode, 
	      CASE Sites.SiteClosed WHEN 1 THEN 'Yes' ELSE 'No' END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNoWaterDispenseSites] TO PUBLIC
    AS [dbo];

