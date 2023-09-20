CREATE PROCEDURE [dbo].[GetWebRegionCleaningOverall] 
(
	@UserID 	INT,
	@FromMonday 	DATETIME,
	@ToMonday	DATETIME,
	@Weekly	BIT = 0
)
AS

SET NOCOUNT ON
DECLARE @AllSites AS BIT
SELECT @AllSites = AllSitesVisible FROM Users JOIN UserTypes ON UserTypes.ID = UserType WHERE Users.ID = @UserID

--Overall
SELECT	DispenseWeek, 
		CASE SUM(ActiveLines) 
		 WHEN 0 THEN 1 
		 ELSE CAST(SUM(ActiveLinesCleaned) AS FLOAT) / CAST(SUM(ActiveLines) AS FLOAT) 
		END AS Effectiveness
FROM (
	SELECT	EDISID, 
			DispenseWeek, 
			CategoryID, 
			SUM(ActiveLines) AS ActiveLines,
			SUM(ActiveLinesCleaned) AS ActiveLinesCleaned
	FROM PeriodCacheCleaning AS Effectiveness
	WHERE (Effectiveness.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID) OR (@AllSites = 1))
	  AND DispenseWeek BETWEEN @FromMonday AND @ToMonday
	GROUP BY EDISID, DispenseWeek, CategoryID) AS SiteCleaning
JOIN (
	SELECT	EDISID, 
			SiteID,
			PostCode,
			ISNULL(ISNULL(ISNULL(ZipCodes.StateName,ExtendedZipCodes.StateName),Address3),'UNKNOWN') AS [Area]
	FROM Sites
	LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ZipCodeAreas AS ZipCodes
		   ON ZipCodes.ZipCode = Sites.PostCode
	LEFT JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.ZipCodeAreas AS ExtendedZipCodes
		   ON ExtendedZipCodes.[State] + ExtendedZipCodes.ZipCode = REPLACE(Sites.PostCode,' ','')) AS SiteDetails
  ON SiteDetails.EDISID = SiteCleaning.EDISID
GROUP BY DispenseWeek


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebRegionCleaningOverall] TO PUBLIC
    AS [dbo];

