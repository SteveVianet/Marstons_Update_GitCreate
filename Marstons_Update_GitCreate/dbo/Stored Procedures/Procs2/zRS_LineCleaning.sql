
-- =============================================
-- Author:		Steven Bain
-- Create date:	18/July/2019
-- Description:	Generic SP to return dataset for all Line Cleaning Reports
--				Replaces bespoke SPs:
--					* zRS_NewLineCleaning
--					* zRS_NewLineCleaningTracker
-- =============================================

CREATE PROCEDURE [dbo].[zRS_LineCleaning]
(
    @From   DATETIME = NULL,
    @To     DATETIME = NULL,
	@ExcludeAles INT = 1						-- 0: Include "Ale - Cask", 1: Exclude "Ale - Cask" (Default)
)
AS
SET NOCOUNT ON

--DECLARE @From   DATETIME = '2019-07-01'
--DECLARE @To     DATETIME = '2019-07-10'

IF @ExcludeAles <> 0
	SET @ExcludeAles = 18;		-- Set CategoryID for "Ale - Cask" (18)
ELSE
	SET @ExcludeAles = -1;		-- Set unused CategoryID (-1) to negate "@ExcludeAles" WHERE criteria

SELECT	RODName AS OM,
		BDMName AS BRM,
		Sites.SiteID,
		Sites.[Name],
		Sites.Address1,
		Sites.Address2,
		Sites.Address3,
		Sites.Address4,
		Sites.PostCode,
		Sites.[Status],
		[Period],
		SUM(TotalDispense) AS TotalDispense,
		SUM(CleanDispense) AS CleanDispense,
		SUM(DueCleanDispense) AS DueCleanDispense,
		SUM(OverdueCleanDispense) AS OverdueCleanDispense,
		Owners.CleaningRedPercentTarget,
		Owners.CleaningAmberPercentTarget,
		CASE 
			WHEN SUM(TotalDispense) = 0
				THEN 0
			ELSE (SUM(OverdueCleanDispense) / SUM(TotalDispense)) * 100
		END AS PercentServedUnclean,
		CASE 
			WHEN SUM(TotalDispense) = 0
				THEN 'No Trade'
			WHEN (SUM(OverdueCleanDispense) / SUM(TotalDispense)) * 100 > Owners.CleaningRedPercentTarget
				THEN 'Red'
			WHEN (SUM(OverdueCleanDispense) / SUM(TotalDispense)) * 100 > Owners.CleaningAmberPercentTarget
				THEN 'Amber'
			ELSE 'Green'					-- <5% of total dispense
		END AS TrafficLight,
		Quality,
		Owners.[Name] AS [Owner]
FROM	PeriodCacheCleaningDispense
			JOIN Sites ON Sites.EDISID = PeriodCacheCleaningDispense.EDISID
			JOIN Owners ON Owners.ID = Sites.OwnerID
			JOIN PubcoCalendars ON PeriodCacheCleaningDispense.[Date] BETWEEN PubcoCalendars.FromWC AND PubcoCalendars.ToWC
			JOIN
			(
				SELECT 
					Sites.EDISID,
					Regions.[Description] AS Regn,
					Areas.[Description] AS Area,
					RODUsers.UserName AS RODName,
					BDMUsers.UserName AS BDMName
				FROM
				(
					SELECT UserSites.EDISID,
						MAX(CASE 
								WHEN Users.UserType = 1
									THEN UserID
								ELSE 0
								END) AS RODID,
						MAX(CASE 
								WHEN Users.UserType = 2
									THEN UserID
								ELSE 0
								END) AS BDMID
					FROM UserSites
					JOIN Users ON Users.ID = UserSites.UserID
					WHERE Users.UserType IN
					(
						1,	-- OSD
						2	-- BDM
					)
					GROUP BY UserSites.EDISID
				) AS UsersTEMP
				JOIN Users AS RODUsers ON RODUsers.ID = UsersTEMP.RODID
				JOIN Users AS BDMUsers ON BDMUsers.ID = UsersTEMP.BDMID
				RIGHT JOIN Sites ON Sites.EDISID = UsersTEMP.EDISID
				JOIN Regions ON Sites.Region = Regions.ID
				JOIN Areas ON Sites.AreaID = Areas.ID
			) AS MYUsers ON MYUsers.EDISID = PeriodCacheCleaningDispense.EDISID
WHERE	[Date] BETWEEN @From AND @To
    AND CategoryID NOT IN
	(
        24,		-- "Spirits"
        27,		-- "Syrup"
        30		-- "Spout"
	)
	AND CategoryID NOT IN (@ExcludeAles)
    AND [Hidden] = 0
	AND Sites.[Status] <> 2					-- SBain (20190709): Exclude Sites "Installed - Closed" for all SPs
--  AND Sites.SiteID NOT LIKE 'HL%'			-- SBain (20190709): Removed for all SPs (no longer required)
GROUP BY	RODName,
			BDMName,
			Sites.SiteID,
			Sites.[Name],
			Sites.Address1,
			Sites.Address2,
			Sites.Address3,
			Sites.Address4,
			Sites.PostCode,
			Sites.[Status],
			[Period],
			Quality,
			Owners.CleaningRedPercentTarget,
			Owners.CleaningAmberPercentTarget,
			Owners.[Name]
ORDER BY	RODName		ASC,
			BDMName		ASC,
			SiteID		ASC,
			[Period]	ASC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_LineCleaning] TO PUBLIC
    AS [dbo];

