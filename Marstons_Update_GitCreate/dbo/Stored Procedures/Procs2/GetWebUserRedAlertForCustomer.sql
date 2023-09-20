--/*
CREATE PROCEDURE [dbo].[GetWebUserRedAlertForCustomer]
(
	@UserID			INT,
	@From			DATETIME,
	@To				DATETIME,
	@RestrictToUserID INT = 0
)
AS
--*/

/* Based on: dbo.GetWebUserRedAlert
    Modifed to restrict the TL/Ranking displayed to the customer.
*/

/* Debug Parameters */
--DECLARE	@UserID			INT = 1541
--DECLARE	@From			DATETIME = '2017-02-06'
--DECLARE	@To				DATETIME = '2017-04-30'
--DECLARE	@RestrictToUserID INT = 0

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @WebAuditDate DATE
SELECT @WebAuditDate = CAST([PropertyValue] AS DATE)
FROM [dbo].[Configuration]
WHERE [PropertyName] = 'AuditDate'

--DECLARE @VisibleStart DATE
--DECLARE @VisibleEnd DATE
--EXEC [dbo].[GetCustomerVisibleDates] @VisibleStart OUTPUT, @VisibleEnd OUTPUT

--SELECT @VisibleStart AS [VisibleStart], @VisibleEnd AS [VisibleEnd]

CREATE TABLE #SiteList (Counter	INT IDENTITY(1,1) PRIMARY KEY,
						EDISID INT NOT NULL, 
						IsIDraught BIT NOT NULL, 
						SiteOnline DATE NOT NULL, 
						TiedDispense FLOAT, 
						Delivery FLOAT, 
						PreviousYearlyDispense FLOAT,
						PreviousThreeMonthDispense FLOAT,
						SiteID VARCHAR(15),
						SiteName VARCHAR(60),
						Town VARCHAR(50))
						
CREATE TABLE #SitesWithSuspectedTampering	(EDISID INT NOT NULL,
											 CaseID INT NOT NULL,
											 EventDate DATETIME NOT NULL,
											 StateID INT NOT NULL)

DECLARE @Anonymise		BIT
DECLARE @UserHasAllSites	BIT
DECLARE @UserTypeID		INTEGER

DECLARE @DatabaseID AS INT
SELECT @DatabaseID = CAST(PropertyValue AS INTEGER) 
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

DECLARE @CashValueOfBarrel FLOAT
SELECT @CashValueOfBarrel = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'CashValueOfBarrel'

DECLARE @OldestStockAllowed AS INT
SELECT @OldestStockAllowed = CASE WHEN PropertyValue IS NULL 
								THEN 6
								ELSE CAST(PropertyValue AS INT) END 
FROM [Configuration] WHERE PropertyName = 'Oldest Stock Weeks Back'

-- Which sites are we allowed to see?
SELECT @UserHasAllSites = AllSitesVisible, @Anonymise = dbo.Users.Anonymise, @UserTypeID = UserTypes.ID
FROM dbo.UserTypes
JOIN dbo.Users ON Users.UserType = UserTypes.[ID]
WHERE dbo.Users.[ID] = @UserID

--This is missing any kind of magic for making grouped sites work
--Get the important site details we need so know where to get our data from
INSERT INTO #SiteList
(EDISID, IsIDraught, SiteOnline, SiteID, SiteName, Town)
SELECT Sites.EDISID, Sites.Quality AS IsIDraught, Sites.SiteOnline, Sites.SiteID, Sites.Name, ISNULL(Address3, Address4)
FROM Sites
WHERE (
		(@UserHasAllSites = 1) OR
		(Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @UserID))
	  )
	  	
AND Sites.EDISID NOT IN (
	  SELECT EDISID
	  FROM SiteGroupSites
	  JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	  WHERE TypeID = 1 AND IsPrimary <> 1
)

AND Sites.EDISID NOT IN (
	SELECT SiteProperties.EDISID
	FROM Properties
	JOIN SiteProperties ON SiteProperties.PropertyID = Properties.ID
	WHERE Properties.[Name] = 'Disposed Status' AND UPPER(SiteProperties.[Value]) = 'YES'
)
AND ((@RestrictToUserID > 0 AND Sites.EDISID IN (SELECT EDISID FROM UserSites WHERE UserID = @RestrictToUserID)) OR @RestrictToUserID = 0)
AND Sites.[Hidden] = 0


-- Anonymise site details for demo purposes if we need to
UPDATE #SiteList
SET  SiteID = 'pub' + CAST([Counter] AS VARCHAR),
	[SiteName] = WebDemoSites.[SiteName],
	Town = WebDemoSites.Town
FROM [SQL1\SQL1].ServiceLogger.dbo.WebDemoSites AS WebDemoSites
WHERE	@Anonymise = 1
	AND [Counter] = WebDemoSites.CounterID

-- If the anonymised site details list doesn't have enough entries, strip all untouched sites for privacy reasons
DELETE FROM #SiteList
WHERE SiteID NOT LIKE 'pub%' AND @Anonymise = 1


--Get tied dispense for both i-draught and dms
UPDATE #SiteList
SET TiedDispense = (SELECT CASE SUM(Dispensed) WHEN 0 THEN NULL ELSE SUM(Dispensed) END AS Dispensed
					FROM dbo.PeriodCacheVariance
					WHERE EDISID = #SiteList.EDISID
					AND WeekCommencing BETWEEN @From AND @To
					AND WeekCommencing >= #SiteList.SiteOnline
					AND IsTied = 1
					GROUP BY EDISID),
    PreviousYearlyDispense = (SELECT CASE SUM(Dispensed) WHEN 0 THEN NULL ELSE SUM(Dispensed) END AS Dispensed
						      FROM dbo.PeriodCacheVariance
						      WHERE EDISID = #SiteList.EDISID
						      AND WeekCommencing BETWEEN DATEADD(WEEK, -52, @From) AND DATEADD(WEEK, -52, @To)
						      AND WeekCommencing >= #SiteList.SiteOnline
						      AND IsTied = 1
						      GROUP BY EDISID),
    PreviousThreeMonthDispense = (SELECT CASE SUM(Dispensed) WHEN 0 THEN NULL ELSE SUM(Dispensed) END AS Dispensed
							      FROM dbo.PeriodCacheVariance
							      WHERE EDISID = #SiteList.EDISID
							      AND WeekCommencing BETWEEN DATEADD(WEEK, -12, @From) AND DATEADD(WEEK, -12, @To)
							      AND WeekCommencing >= #SiteList.SiteOnline
							      AND IsTied = 1
							      GROUP BY EDISID),
    Delivery = (SELECT SUM(Delivered) 
			    FROM PeriodCacheVariance
			    WHERE EDISID = #SiteList.EDISID 
			    AND WeekCommencing BETWEEN @From AND @To
			    AND WeekCommencing >= #SiteList.SiteOnline
			    AND IsTied = 1
			    GROUP BY PeriodCacheVariance.EDISID)


--GET SUSPECTED TAMPERING CASES
INSERT INTO #SitesWithSuspectedTampering(EDISID, CaseID, EventDate, StateID)
	(

	SELECT	MostRecentTamperCases.EDISID,
			MostRecentTamperCases.CaseID,
			MostRecentCaseEvents.EventDate,
			TamperCaseStatuses.StateID
	FROM (
		SELECT  EDISID,
				MAX(TamperCases.CaseID) AS CaseID
		FROM TamperCases
		GROUP BY EDISID
	)AS MostRecentTamperCases
	JOIN (
		SELECT  CaseID,
				MAX(EventDate) AS EventDate
		FROM TamperCaseEvents
		GROUP BY CaseID
	) AS MostRecentCaseEvents ON MostRecentCaseEvents.CaseID = MostRecentTamperCases.CaseID

	JOIN (
		SELECT  CaseID,
				StateID,
				EventDate
		FROM TamperCaseEvents
	) AS TamperCaseStatuses ON (TamperCaseStatuses.CaseID = MostRecentTamperCases.CaseID
		AND TamperCaseStatuses.EventDate = MostRecentCaseEvents.EventDate)
	WHERE TamperCaseStatuses.StateID IN (2,5))



--Return our final result set
SELECT	@DatabaseID AS DatabaseID,
		Sites.EDISID,
		SiteList.SiteID, 
		SiteList.SiteName AS SiteName, 
		SiteList.Town AS Town,
		CASE WHEN OutstandingCalls.EDISID IS NULL
			 THEN 99 -- No Status
			 ELSE 1 -- Red
		END AS OutstandingCalls,
		NULL AS StockVariance,
		((SiteList.Delivery - SiteList.TiedDispense)) AS CumulativeVariance,
		((SiteList.Delivery - SiteList.TiedDispense) / SiteList.TiedDispense) * 100 AS CumulativeVariancePercent,
		CASE WHEN (SiteList.Delivery - SiteList.TiedDispense) < 0 THEN ((((SiteList.Delivery - SiteList.TiedDispense)/8)/ 36) * @CashValueOfBarrel) ELSE 0 END AS CashValue,
		NULL AS MetricVariance,
		REDValues.Value AS RedValue,
		TiedDispense AS TotalDispense,
		Stock.LatestStock AS Stock,
		CASE WHEN Stock.LatestStock IS NOT NULL
			 THEN CASE WHEN Stock.LatestStock < DATEADD(WEEK, -@OldestStockAllowed, @From)
					   THEN 1
					   ELSE 0
				  END
			 ELSE NULL
		 END AS StockTooOld,
		CASE WHEN SuspectedTampering.SeverityID IS NULL
			 THEN NULL -- No Tampering logged for site
			 WHEN SuspectedTampering.SeverityID = 0
			 THEN NULL -- Resolved, ignore
			 WHEN SuspectedTampering.SeverityID = 3
			 THEN 1 -- High (Red)
			 ELSE 2 -- Normal (Yellow)
		 END AS SuspectedTampering,
		CASE WHEN OutstandingVRS.EDISID IS NULL
			 THEN 99 -- No Status
			 ELSE 1 -- Red
		 END AS OutstandingVRSNote,
		 '' AS TieCompliancePDF,
		(SiteList.TiedDispense - SiteList.PreviousYearlyDispense) /  SiteList.PreviousYearlyDispense * 100 AS PreviousYearPercentage,	
		(SiteList.TiedDispense - SiteList.PreviousThreeMonthDispense) /  SiteList.PreviousThreeMonthDispense * 100 AS PreviousThreeMonthPercentage,	
		0 AS ActiveLines,
		0 AS ActiveLinesCleaned,
		0 AS CleanDays,
		0 AS InToleranceDays,
		0 AS OverdueCleanDays,
		'' AS LineCleaningPerformance,
		'' AS LowVolumeReport,
		'' AS BusinessBuildingPDF,
		OutstandingVRSRecord.VisitID AS OutstandingVisitID,
		SiteRankingCurrent.Audit AS SiteStatus,
		SuspectedTampering.MostRecentCase AS MostRecentTamperCase,
		SuspectedTampering.[Description]AS TamperCaseDescription, 
		SuspectedTampering.[Text] AS TamperCaseText,
		SuspectedTampering.Type1Description AS TamperingType1,
		SuspectedTampering.Type2Description AS TamperingType2,
		SuspectedTampering.Type3Description AS TamperingType3,
		SuspectedTampering.Type4Description AS TamperingType4,
		SuspectedTampering.Type5Description AS TamperingType5,
		SuspectedTampering.Type6Description AS TamperingType6,
		SuspectedTampering.Type7Description AS TamperingType7,
		SuspectedTampering.Type8Description	AS TamperingType8,
		Sites.SiteClosed,
		OverdueDispensePercentage,
		TotalDispense AS TotalCleanDispense,
		OverdueDispense AS OverdueCleanDispense,
		Owners.CleaningAmberPercentTarget,
		Owners.CleaningRedPercentTarget
FROM #SiteList AS SiteList
JOIN Sites ON Sites.EDISID = SiteList.EDISID
JOIN Owners ON Sites.OwnerID = Owners.ID
LEFT OUTER JOIN (
	SELECT EDISID, 
		   CASE WHEN SUM(TotalDispense) = 0 THEN 0 ELSE (SUM(OverdueDispense) / SUM(TotalDispense) * 100) END AS OverdueDispensePercentage,
		   TotalDispense,
		   OverdueDispense
	FROM
	(
		SELECT	EDISID,
				SUM(PeriodCacheCleaningDispense.TotalDispense) AS TotalDispense,
				SUM(PeriodCacheCleaningDispense.OverdueCleanDispense) AS OverdueDispense
		FROM PeriodCacheCleaningDispense 
		JOIN ProductCategories ON ProductCategories.ID = PeriodCacheCleaningDispense.CategoryID
			AND ProductCategories.IncludeInLineCleaning = 1 
		WHERE PeriodCacheCleaningDispense.[Date] BETWEEN @From AND @To
		GROUP BY EDISID
	) AS OverduePercentage
	GROUP BY EDISID, TotalDispense, OverdueDispense) AS PeriodCleaningPercentage ON PeriodCleaningPercentage.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT MasterDates.EDISID, MAX(CAST(MasterDates.[Date] AS DATE)) AS LatestStock 
	FROM Stock
	JOIN MasterDates ON MasterDates.ID = Stock.MasterDateID
	GROUP BY MasterDates.EDISID
	) AS Stock ON Stock.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT CurrentCalls.EDISID
	FROM (
		SELECT EDISID, MAX(RaisedOn) AS RaisedOn
		FROM Calls
		GROUP BY EDISID
	) AS CurrentCalls
	JOIN Calls ON (Calls.RaisedOn = CurrentCalls.RaisedOn AND Calls.EDISID = CurrentCalls.EDISID)
	WHERE AbortReasonID = 0 AND Calls.ClosedOn IS NULL
) AS OutstandingCalls ON OutstandingCalls.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT EDISID, ISNULL(SUM(CD), 0) AS Value
	FROM Reds
	WHERE Period = (SELECT TOP 1 Period
					FROM PubcoCalendars
					WHERE Processed = 1
					ORDER BY FromWC DESC)
	GROUP BY EDISID
	) AS REDValues
  ON REDValues.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT DISTINCT VisitRecords.EDISID
	FROM VisitRecords
	WHERE VerifiedByVRS = 1
	  AND CompletedByCustomer IS NULL
	  AND Deleted = 0
	) AS OutstandingVRS
  ON OutstandingVRS.EDISID = Sites.EDISID
LEFT OUTER JOIN (
	SELECT MAX(VisitRecords.ID) AS VisitID, VisitRecords.EDISID
	FROM VisitRecords
	WHERE VerifiedByVRS = 1
	  AND CompletedByCustomer IS NULL
	  AND Deleted = 0
	GROUP BY VisitRecords.EDISID
	) AS OutstandingVRSRecord
  ON OutstandingVRSRecord.EDISID = Sites.EDISID
/*
LEFT OUTER JOIN SiteRankingCurrent
  ON SiteRankingCurrent.EDISID = Sites.EDISID
*/
LEFT OUTER JOIN (
    SELECT 
        [SiteRankings].[EDISID],
        [SiteRankings].[RankingTypeID] AS [Audit]
    FROM [dbo].[SiteRankings]
    JOIN (  SELECT 
                [EDISID],
                MAX([SiteRankings].[ValidTo]) AS [ValidTo]
            FROM [dbo].[SiteRankings]
            WHERE [ValidFrom] BETWEEN @WebAuditDate AND DATEADD(DAY, 6, @WebAuditDate)
            GROUP BY [EDISID]
            ) AS [LatestRanking] 
            ON [LatestRanking].[EDISID] = [SiteRankings].[EDISID]
            AND [LatestRanking].ValidTo = [SiteRankings].[ValidTo]
) AS SiteRankingCurrent ON SiteRankingCurrent.EDISID = Sites.EDISID 

---- join on suspected tampering details 
LEFT OUTER JOIN (
	   SELECT #SitesWithSuspectedTampering.EventDate AS MostRecentCase,
	   #SitesWithSuspectedTampering.EDISID AS EDISID,
	   #SitesWithSuspectedTampering.CaseID,   	   
	   TamperCaseEvents.[Text],
	   Severity.[Description],
	   TamperCaseEvents.SeverityID,
	   TamperCaseEvents.TypeListID,
	   TypeDescriptions.Type1Description,
	   TypeDescriptions.Type2Description,
	   TypeDescriptions.Type3Description,
	   TypeDescriptions.Type4Description,
	   TypeDescriptions.Type5Description,
	   TypeDescriptions.Type6Description,
	   TypeDescriptions.Type7Description,
	   TypeDescriptions.Type8Description
	   FROM TamperCases
JOIN TamperCaseEvents ON TamperCaseEvents.CaseID = TamperCases.CaseID
JOIN #SitesWithSuspectedTampering ON  #SitesWithSuspectedTampering.EDISID = TamperCases.EDISID
LEFT JOIN (
		SELECT  RefID,
				MAX(CASE WHEN TypeID = 1 THEN TypeDescriptions.Description ELSE '' END) AS Type1Description,
				MAX(CASE WHEN TypeID = 2 THEN TypeDescriptions.Description ELSE '' END) AS Type2Description,
				MAX(CASE WHEN TypeID = 3 THEN TypeDescriptions.Description ELSE '' END) AS Type3Description,
				MAX(CASE WHEN TypeID = 4 THEN TypeDescriptions.Description ELSE '' END) AS Type4Description,
				MAX(CASE WHEN TypeID = 5 THEN TypeDescriptions.Description ELSE '' END) AS Type5Description,
				MAX(CASE WHEN TypeID = 6 THEN TypeDescriptions.Description ELSE '' END) AS Type6Description,
				MAX(CASE WHEN TypeID = 7 THEN TypeDescriptions.Description ELSE '' END) AS Type7Description,
				MAX(CASE WHEN TypeID = 8 THEN TypeDescriptions.Description ELSE '' END) AS Type8Description
		FROM TamperCaseEventTypeList
		JOIN TamperCaseEventTypeDescriptions AS TypeDescriptions ON TypeDescriptions.ID = TamperCaseEventTypeList.TypeID
		GROUP BY TamperCaseEventTypeList.RefID) AS TypeDescriptions ON  TypeDescriptions.RefID = TamperCaseEvents.TypeListID
LEFT JOIN TamperCaseEventsSeverityDescriptions AS Severity ON Severity.ID = TamperCaseEvents.SeverityID
WHERE TamperCaseEvents.EventDate = #SitesWithSuspectedTampering.EventDate
GROUP BY   #SitesWithSuspectedTampering.EDISID, 
		   #SitesWithSuspectedTampering.CaseID,	   	   
		   #SitesWithSuspectedTampering.EventDate, 
		   TamperCaseEvents.[Text], 
		   Severity.[Description], 
		   #SitesWithSuspectedTampering.StateID,
		   TamperCaseEvents.SeverityID,
		   TamperCaseEvents.TypeListID,
		   TypeDescriptions.Type1Description,
		   TypeDescriptions.Type2Description,
		   TypeDescriptions.Type3Description,
		   TypeDescriptions.Type4Description,
		   TypeDescriptions.Type5Description,
		   TypeDescriptions.Type6Description,
		   TypeDescriptions.Type7Description,
		   TypeDescriptions.Type8Description)AS SuspectedTampering ON SuspectedTampering.EDISID = Sites.EDISID
ORDER By Sites.EDISID

DROP TABLE #SiteList
DROP TABLE #SitesWithSuspectedTampering

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserRedAlertForCustomer] TO PUBLIC
    AS [dbo];

