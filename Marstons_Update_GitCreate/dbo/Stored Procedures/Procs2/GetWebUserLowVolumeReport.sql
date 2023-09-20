CREATE PROCEDURE [dbo].[GetWebUserLowVolumeReport]
(
	@UserID	INT,
	@From	DATETIME,
	@To		DATETIME,
	@Development BIT = 0,
	@IncludeDMS BIT = 1
)
AS

/*
DECLARE	@UserID	INT                     = 20
DECLARE	@From	DATETIME                = '2013-03-25'
DECLARE	@To		DATETIME                = '2013-06-16'
DECLARE	@Development BIT = 0
DECLARE	@IncludeDMS BIT = 1
*/

DECLARE @RelevantSites TABLE (
	EDISID INT NOT NULL,
	PrimaryEDISID INT,
	SiteGroupID INT,
	IsPrimary BIT DEFAULT(1),
	Cellar INT DEFAULT(1),
	MaxPump INT DEFAULT(0),
	PumpOffset INT DEFAULT(0),
	SiteOnline DATE
	)

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @IsAllSitesVisible   BIT
DECLARE @EDISDatabaseID		 INT

SELECT @EDISDatabaseID = CAST(PropertyValue AS INT)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @IsAllSitesVisible = UserTypes.AllSitesVisible
FROM Users
JOIN UserTypes ON UserTypes.ID = Users.UserType
WHERE Users.ID = @UserID

IF @IsAllSitesVisible = 0
BEGIN
	--Add Sites which are Single-Cellar
    INSERT INTO @RelevantSites (
	    EDISID,
	    PrimaryEDISID,
	    SiteOnline
	    )
    SELECT Sites.EDISID,
	    Sites.EDISID,
	    Sites.SiteOnline
    FROM Sites
    JOIN UserSites ON UserSites.EDISID = Sites.EDISID
    LEFT JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
    WHERE SiteGroupSites.EDISID IS NULL
        AND UserID = @UserID
	    AND Sites.Hidden = 0
	    AND (
		    @IncludeDMS = 1
		    OR Sites.Quality = 1
		    )

    --Add Sites which are Multi-Cellar
    INSERT INTO @RelevantSites (
	    EDISID,
	    SiteGroupID,
	    IsPrimary,
	    Cellar
	    )
    SELECT SiteGroupSites.EDISID,
	    SiteGroupSites.SiteGroupID AS SiteGroupID,
	    --SiteGroups.[Description] AS GroupName,
	    --SiteGroupTypes.[Description] AS GroupType,
	    CASE 
		    WHEN HasPrimary = 1
			    THEN IsPrimary
		    ELSE NULL
		    END AS IsPrimary,
	    ROW_NUMBER() OVER (
		    PARTITION BY SiteGroups.ID ORDER BY IsPrimary DESC
		    ) AS Cellar
    FROM SiteGroupSites
    JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
    JOIN UserSites ON UserSites.EDISID = Sites.EDISID
    JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
    JOIN SiteGroupTypes ON SiteGroupTypes.ID = SiteGroups.TypeID
    WHERE SiteGroups.TypeID = 1
        AND UserID = @UserID
	    AND Sites.Hidden = 0
	    AND (
		    @IncludeDMS = 1
		    OR Sites.Quality = 1
		    )
    ORDER BY SiteGroupID ASC,
	    IsPrimary DESC
END
ELSE
BEGIN
    --Add Sites which are Single-Cellar
    INSERT INTO @RelevantSites (
	    EDISID,
	    PrimaryEDISID,
	    SiteOnline
	    )
    SELECT Sites.EDISID,
	    Sites.EDISID,
	    Sites.SiteOnline
    FROM Sites
    LEFT JOIN SiteGroupSites ON SiteGroupSites.EDISID = Sites.EDISID
    WHERE SiteGroupSites.EDISID IS NULL
	    AND Sites.Hidden = 0
	    AND (
		    @IncludeDMS = 1
		    OR Sites.Quality = 1
		    )

    --Add Sites which are Multi-Cellar
    INSERT INTO @RelevantSites (
	    EDISID,
	    SiteGroupID,
	    IsPrimary,
	    Cellar
	    )
    SELECT SiteGroupSites.EDISID,
	    SiteGroupSites.SiteGroupID AS SiteGroupID,
	    --SiteGroups.[Description] AS GroupName,
	    --SiteGroupTypes.[Description] AS GroupType,
	    CASE 
		    WHEN HasPrimary = 1
			    THEN IsPrimary
		    ELSE NULL
		    END AS IsPrimary,
	    ROW_NUMBER() OVER (
		    PARTITION BY SiteGroups.ID ORDER BY IsPrimary DESC
		    ) AS Cellar
    FROM SiteGroupSites
    JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
    JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
    JOIN SiteGroupTypes ON SiteGroupTypes.ID = SiteGroups.TypeID
    WHERE SiteGroups.TypeID = 1
	    AND Sites.Hidden = 0
	    AND (
		    @IncludeDMS = 1
		    OR Sites.Quality = 1
		    )
    ORDER BY SiteGroupID ASC,
	    IsPrimary DESC
END

--Set the Primary EDISID for Multi-Cellars
UPDATE RelevantSites
SET RelevantSites.PrimaryEDISID = PrimarySites.EDISID,
	RelevantSites.SiteOnline = ISNULL(RelevantSites.SiteOnline, Sites.SiteOnline)
FROM @RelevantSites AS RelevantSites
JOIN (
	SELECT EDISID,
		SiteGroupID
	FROM @RelevantSites
	WHERE IsPrimary = 1
		AND SiteGroupID IS NOT NULL
	) AS PrimarySites ON PrimarySites.SiteGroupID = RelevantSites.SiteGroupID
JOIN Sites ON Sites.EDISID = RelevantSites.EDISID

--Set the current Max Pump number for each cellar/site
UPDATE RelevantSites
SET RelevantSites.MaxPump = Pumps.MaxPump
FROM @RelevantSites AS RelevantSites
JOIN (
	SELECT PumpSetup.EDISID,
		MAX(Pump) AS MaxPump
	FROM @RelevantSites AS RelevantSites
	JOIN PumpSetup ON PumpSetup.EDISID = RelevantSites.EDISID
	WHERE (ValidFrom <= @To)
		AND (ISNULL(ValidTo, @To) >= @From)
		AND (ISNULL(ValidTo, @To) >= RelevantSites.SiteOnline)
	GROUP BY PumpSetup.EDISID,
		RelevantSites.Cellar
	) AS Pumps ON Pumps.EDISID = RelevantSites.EDISID

--Set the PumpOffset values for cellars past the primary
--This may loop several times depending on how many cellars a site has
WHILE (
		SELECT COUNT(*)
		FROM @RelevantSites AS RelevantSites
		LEFT JOIN @RelevantSites AS PreviousRow ON PreviousRow.Cellar = RelevantSites.Cellar - 1
			AND PreviousRow.SiteGroupID = RelevantSites.SiteGroupID
		WHERE RelevantSites.SiteGroupID IS NOT NULL
			AND RelevantSites.PumpOffset < (PreviousRow.PumpOffset + PreviousRow.MaxPump)
		) > 0
BEGIN
	UPDATE RelevantSites
	SET RelevantSites.PumpOffset = PreviousRow.PumpOffset + PreviousRow.MaxPump
	FROM @RelevantSites AS RelevantSites
	JOIN @RelevantSites AS PreviousRow ON PreviousRow.Cellar = RelevantSites.Cellar - 1
		AND PreviousRow.SiteGroupID = RelevantSites.SiteGroupID
	WHERE RelevantSites.SiteGroupID IS NOT NULL
		AND RelevantSites.PumpOffset < (PreviousRow.PumpOffset + PreviousRow.MaxPump)
END

/* Debugging */
--SELECT *
--FROM @RelevantSites
--ORDER BY PrimaryEDISID ASC,
--	Cellar ASC

SELECT	@EDISDatabaseID AS [DBID],
		RelevantSites.PrimaryEDISID AS EDISID,
		SiteDetails.SiteID,
		SiteDetails.SiteID + ': ' + SiteDetails.Name + ', ' + COALESCE(SiteDetails.Address2, SiteDetails.Address3, SiteDetails.Address4) + ', ' + SiteDetails.PostCode AS Name,
		BDMUser.UserName AS BDMName,
		RMUser.UserName AS RMName,
		WeeklyDispense.Pump + RelevantSites.PumpOffset AS Pump,
		Products.[Description] AS Product,
		ProductCategories.[Description] AS ProductCategory,
		Owners.ThroughputLowValue,
		AVG(WeeklyDispense.Volume) AS AverageWeeklyVolume,
		SUM(WeeklyDispense.Volume) AS TotalWeeklyVolume,
		AVG(WeeklyDispense.WastedVolume) AS AverageWastedVolume,
		SUM(WeeklyDispense.WastedVolume) AS TotalWastedVolume
FROM PeriodCacheTradingDispenseWeekly AS WeeklyDispense
JOIN Products ON Products.ID = WeeklyDispense.ProductID
JOIN ProductCategories ON ProductCategories.ID = Products.CategoryID
JOIN Locations ON Locations.ID = WeeklyDispense.LocationID
JOIN @RelevantSites AS RelevantSites ON RelevantSites.EDISID = WeeklyDispense.EDISID
JOIN Sites AS SiteDetails ON SiteDetails.EDISID = RelevantSites.PrimaryEDISID
JOIN (	SELECT UserSites.EDISID,
 			MAX(CASE WHEN UserType = 2 THEN UserID ELSE 0 END) AS BDMID,
			MAX(CASE WHEN UserType = 1 THEN UserID ELSE 0 END) AS RMID
		FROM UserSites
		JOIN Users ON Users.ID = UserSites.UserID
		JOIN @RelevantSites AS Sites ON UserSites.EDISID = Sites.EDISID
		WHERE UserType IN (1,2) AND UserSites.EDISID = Sites.EDISID
		GROUP BY UserSites.EDISID
	) AS SiteManagers
  ON SiteManagers.EDISID = WeeklyDispense.EDISID
JOIN Users AS BDMUser ON BDMUser.ID = SiteManagers.BDMID
JOIN Users AS RMUser ON RMUser.ID = SiteManagers.RMID
JOIN Owners ON SiteDetails.OwnerID = Owners.ID
WHERE WeeklyDispense.WeekCommencing BETWEEN @From AND @To
  AND Products.IncludeInLowVolume = 1
  AND Products.IsMetric = 0
  AND ProductCategories.IncludeInEstateReporting = 1
GROUP BY	RelevantSites.PrimaryEDISID,
			SiteDetails.SiteID,
			SiteDetails.Name,
			COALESCE(SiteDetails.Address2, SiteDetails.Address3, SiteDetails.Address4),
			SiteDetails.PostCode,
			BDMUser.UserName,
			RMUser.UserName,
			WeeklyDispense.Pump + RelevantSites.PumpOffset,
			Products.[Description],
			ProductCategories.[Description],
			Owners.ThroughputLowValue
HAVING AVG(WeeklyDispense.Volume) < Owners.ThroughputLowValue


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserLowVolumeReport] TO PUBLIC
    AS [dbo];

