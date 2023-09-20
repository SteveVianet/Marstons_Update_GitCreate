CREATE PROCEDURE RedAlertVRSCAMReportPack 
	@ScheduleID INT = NULL,
	@EDISID INT = NULL,
	@From DATE,
	@To DATE,
	@ShowHidden BIT = 0
WITH RECOMPILE
AS
BEGIN
	
	SET NOCOUNT ON;

    --Get Dispensed Data
	DECLARE @dispensed TABLE	( 
		EDISID INT,
		Dispensed FLOAT
		)

	INSERT INTO @dispensed
	SELECT 
		ss.EDISID,
		SUM(dld.Quantity) AS TotalDispensed
	FROM DLData AS dld
		INNER JOIN MasterDates as md ON md.[ID] = dld.DownloadID
		INNER JOIN Products AS p ON p.[ID] = dld.Product
		INNER JOIN Sites AS s ON s.EDISID = md.EDISID
		LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
		LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	
	WHERE 
	 COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
		AND md.[Date] >= s.SiteOnline
	GROUP BY ss.EDISID
	ORDER BY EDISID

--Get Delivered Data
	DECLARE @delivered TABLE(
		EDISID INT,
		Delivered FLOAT
		)

	INSERT INTO @delivered
	SELECT 
		ss.EDISID,
		SUM(del.Quantity/0.125) AS TotalDelivered
	FROM Delivery AS del
		INNER JOIN MasterDates as md ON md.[ID] = del.DeliveryID
		INNER JOIN Sites AS s ON s.EDISID = md.EDISID
		INNER JOIN Products AS p ON p.[ID] = del.Product
		LEFT JOIN SiteProductTies AS spt ON  spt.EDISID =s.EDISID AND spt.ProductID = p.[ID]
		LEFT JOIN SiteProductCategoryTies AS spct ON spct.EDISID = s.EDISID AND p.CategoryID = spct.ProductCategoryID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	
	WHERE 
		COALESCE(spt.Tied, spct.Tied, p.Tied) = 1
		AND md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
		AND md.[Date] >= s.SiteOnline
	GROUP BY ss.EDISID
	ORDER BY EDISID

	--Get BDM for each site
	DECLARE @BDM TABLE	( 
		ID INT,
		UserName VARCHAR(30),
		EDISID INT
		)

	INSERT INTO @BDM
	SELECT	u.ID,
		u.UserName,
		s.EDISID
	FROM Users As u
		INNER JOIN UserSites as us ON us.UserID = u.ID
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
	WHERE u.UserType = 2

	--Get Untied Dispensed Volumes

	DECLARE @UntiedDispensed TABLE (
		EDISID INT,
		Dispensed FLOAT
		)

	INSERT INTO @UntiedDispensed
	SELECT 
		ss.EDISID,
		SUM(dld.Quantity) AS Dispensed
	FROM DLData AS dld
		INNER JOIN MasterDates as md ON md.[ID] = dld.DownloadID
		INNER JOIN Products AS p ON p.[ID] = dld.Product
		INNER JOIN Sites AS s ON s.EDISID = md.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	
	WHERE 
		md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
		AND md.[Date] >= s.SiteOnline
	GROUP BY ss.EDISID
	ORDER BY EDISID

	--Get Untied Delivered Data
	DECLARE @UntiedDelivered TABLE(
		EDISID INT,
		Delivered FLOAT
		)

	INSERT INTO @UntiedDelivered
	SELECT 
		ss.EDISID,
		SUM(del.Quantity/0.125) AS Delivered
	FROM Delivery AS del
		INNER JOIN MasterDates as md ON md.[ID] = del.DeliveryID
		INNER JOIN Sites AS s ON s.EDISID = md.EDISID
		INNER JOIN Products AS p ON p.[ID] = del.Product
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE 
		md.[Date] BETWEEN @From AND DATEADD("d", 6, @To)
		AND md.[Date] >= s.SiteOnline
	GROUP BY ss.EDISID
	ORDER BY EDISID

	--Get Tampering Level

	DECLARE @Tampering TABLE(
		EDISID INT,
		TamperingLevel VARCHAR(50),
		DateLevelApplied DATE
		)

	INSERT INTO @Tampering
	SELECT tc.EDISID,
		   tcesd.[Description],
		   tce.EventDate
	FROM TamperCases AS tc
		INNER JOIN TamperCaseEvents AS tce ON tce.CaseID = tc.CaseID
		INNER JOIN TamperCaseEventsSeverityDescriptions AS tcesd ON tcesd.ID = tce.SeverityID
		INNER JOIN Sites AS s ON s.EDISID = tc.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE tce.EventDate = (SELECT MAX(tce2.EventDate)
							FROM TamperCaseEvents AS tce2 
								INNER JOIN (SELECT EDISID, MAX(CaseID) AS MaxCaseID FROM TamperCases AS tc2 Group By EDISID) AS MaxCase ON tc.CaseID = MaxCase.MaxCaseID
							WHERE tce2.CaseID = tce.CaseID)

	DECLARE @SVC TABLE(
		EDISID INT,
		Period Date
		)

	INSERT INTO @SVC
	SELECT c.EDISID,
	   csh.ChangedOn
	FROM Calls AS c 
		LEFT JOIN CallStatusHistory AS csh ON csh.CallID = c.ID
		INNER JOIN Sites AS s ON c.EDISID = s.EDISID
		INNER JOIN (SELECT DISTINCT EDISID
				FROM ScheduleSites AS ss
				WHERE ss.ScheduleID = 236 AND (ss.EDISID = @EDISID or @EDISID IS NULL)
				)AS ss ON s.EDISID = ss.EDISID
  
	WHERE StatusID != 4 AND StatusID != 5 AND StatusID != 6 --AND StatusID != 1
	--AND CallTypeID = 1
	AND ChangedOn = (SELECT MAX(ChangedOn) FROM Calls AS c2 LEFT JOIN CallStatusHistory AS csh2 ON csh2.CallID = c2.ID WHERE c2.EDISID = c.EDISID)
	--AND ChangedOn BETWEEN '2016-03-07' AND '2016-07-04'
 


	--Get traffic light colour for sites based on Site Ranking

		DECLARE @SiteTrafficLights TABLE(
			EDISID INT,
			ValidFrom DateTime,
			ValidTo DateTime,
			RankingTypeID INT,
			Colour INT,
			Name VARCHAR(10),
			HexColour VARCHAR(20)
			)

		INSERT INTO @SiteTrafficLights
		SELECT DISTINCT
			sr.EDISID,
			ValidFrom,
			ValidTo,
			RankingTypeID,
			srt.Colour,
			srt.Name,

		CASE 
			WHEN srt.Name = 'Red' THEN '#ff0000'
			WHEN srt.Name = 'Amber' THEN 'Orange'
			WHEN srt.Name = 'Green' THEN '#33cc33'
			WHEN srt.Name = 'Grey' THEN 'Gray'
			WHEN srt.Name = 'Blue' THEN 'Blue'
			ELSE '#ffffff'
		END AS HexColour

		FROM dbo.SiteRankings AS sr
			LEFT JOIN SiteRankingTypes as srt ON  sr.RankingTypeID = srt.ID
			LEFT JOIN Sites AS s ON s.EDISID = sr.EDISID
			LEFT JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
		WHERE ValidFrom = (SELECT Max(ValidFrom) FROM SiteRankings AS sr2 WHERE sr2.EDISID = sr.EDISID)
			AND RankingTypeID = (SELECT MIN(RankingTypeID) FROM SiteRankings sr3 INNER JOIN SiteRankingTypes AS srt2 ON srt2.ID = srt.ID WHERE sr3.EDISID = sr.EDISID)
		ORDER BY EDISID, ValidFrom desc

	-- Taking into account for Multi Cellar

	DECLARE @Sites TABLE (
		EDISID INT,
		SiteID VARCHAR(50),
		Name VARCHAR(50),
		Address1 VARCHAR(50),
		Address2 VARCHAR(50),
		Address3 VARCHAR(50),
		PostCode VARCHAR(50),
		SiteOnline SMALLDATETIME,
		Hidden BIT
		)

	INSERT INTO @Sites

	SELECT DISTINCT ss.EDISID, s.SiteID, s.Name, s.Address1, s.Address2,s.Address3,s.PostCode,s.SiteOnline,s.Hidden
	FROM ScheduleSites AS ss
		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s	
				LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs ON sgs.EDISID = ss.EDISID

		LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		INNER JOIN Sites AS s ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
	WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (s.EDISID = @EDISID or @EDISID IS NULL)

    -- Main Select Statement

	SELECT DISTINCT
		ISNULL(BDM.UserName,'None') AS BDM,
		s.SiteID,
		s.Name,
		CASE 
			WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
			WHEN s.Address3 = '' THEN s.Address2
			ELSE s.Address3
		END AS Town,

		s.PostCode,
		CASE 
			WHEN vr.PhysicallyAgressive = 1 THEN 'Yes'
			ELSE 'No'
		END AS HighRiskStatus,

		CASE
			WHEN s.SiteOnline <= @From THEN DATEDIFF(week,@From,DATEADD("d", 6, @To))
			ELSE DATEDIFF(week,s.SiteOnline,DATEADD("d", 6, @To))
		END AS WeeksOnline, 

		ROUND(ISNULL(d.Dispensed, 0), 2) AS Dispensed,
		ROUND(ISNULL(del.Delivered, 0), 2) AS Delivered,
		ROUND(ISNULL(del.Delivered, 0) - ISNULL(d.Dispensed, 0), 2) AS Variance,
		ROUND(ISNULL(ud.Dispensed,0) - ISNULL(d.Dispensed, 0), 2) AS UntiedDispensed,
		ROUND(ISNULL(udel.Delivered,0) - ISNULL(del.Delivered, 0), 2) AS UntiedDelivered,
		ROUND((ISNULL(udel.Delivered,0) - ISNULL(del.Delivered, 0)) - (ISNULL(ud.Dispensed,0) - ISNULL(d.Dispensed, 0)), 2) AS UntiedVariance,

		CASE	
			WHEN pfs.GlasswareStateID = 0 THEN 'No'
			WHEN pfs.GlasswareStateID = 1 THEN 'Full'
			WHEN pfs.GlasswareStateID = 2 THEN 'Partially'
			WHEN pfs.GlasswareStateID = 3 THEN 'Key Products'
			WHEN pfs.GlasswareStateID = 4 THEN 'Unknown'
		END AS Glass,

		ISNULL(t.TamperingLevel, '') AS TamperingLevel,
		ISNULL(CONVERT(VARCHAR(50),t.DateLevelApplied), '') AS DateLevelApplied,
		ISNULL(CONVERT(VARCHAR(50),svc.Period), '') AS SVCinPeriod,
		ISNULL(stl.HexColour,'#ffffff') AS TrafficLightColour
	FROM @Sites AS s
		LEFT JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
		LEFT JOIN @dispensed AS d ON s.EDISID = d.EDISID
		LEFT JOIN @delivered AS del ON s.EDISID = del.EDISID
		LEFT JOIN UserSites AS us ON s.EDISID = us.EDISID
		LEFT JOIN @BDM as BDM ON us.EDISID = BDM.EDISID
		LEFT JOIN @UntiedDispensed AS ud ON s.EDISID = ud.EDISID
		LEFT JOIN @UntiedDelivered AS udel ON s.EDISID = udel.EDISID
		LEFT JOIN @Tampering AS t ON s.EDISID = t.EDISID
		LEFT JOIN @SiteTrafficLights AS stl ON s.EDISID = stl.EDISID
		INNER JOIN ProposedFontSetups AS pfs ON s.EDISID = pfs.EDISID
		LEFT JOIN @SVC AS svc ON svc.EDISID = s.EDISID
		LEFT JOIN VisitRecords AS vr ON vr.EDISID = s.EDISID
	WHERE (s.Hidden = 0 or @ShowHidden = 1) 
		AND (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) 
		AND (s.EDISID = @EDISID or @EDISID IS NULL)
		AND pfs.CreateDate =(SELECT MAX(CreateDate) AS CreateDate
							  FROM ProposedFontSetups 
							  WHERE ProposedFontSetups.EDISID = pfs.EDISID
								AND Available = 1
							  )
	GROUP BY s.SiteID, s.Name,s.Address1,s.Address2,s.Address3,s.SiteOnline,d.Dispensed,del.Delivered,BDM.UserName, ud.Dispensed, udel.Delivered,pfs.GlasswareStateID,t.TamperingLevel,t.DateLevelApplied,svc.Period,vr.PhysicallyAgressive, stl.HexColour, s.EDISID,s.PostCode
	ORDER BY Variance

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RedAlertVRSCAMReportPack] TO PUBLIC
    AS [dbo];

