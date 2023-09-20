CREATE PROCEDURE [dbo].[GetReportPackRedAlert](
	@EDISID INT = NULL,
	@UserID INT = NULL,
	@From DATETIME,
	@To DATETIME
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	SET DATEFIRST 1

	--Get VRS Admission Types
	DECLARE @Admission AS TABLE ([ID] INT, [Description] NVARCHAR(100))
	INSERT INTO @Admission EXEC [SQL1\SQL1].[ServiceLogger].[dbo].GetVRSAdmission
	
	-- Combine multi-cellar sites
	DECLARE @MultiCellarSites AS TABLE	(
		EDISID INT,
		PrimaryEDISID INT,
		SiteID VARCHAR(50),
		Name VARCHAR(50),
		Town VARCHAR(50),
		PostCode VARCHAR(50),
		BDM VARCHAR(50),
		SiteClosed BIT
	)

	INSERT INTO @MultiCellarSites
	SELECT DISTINCT us.EDISID, COALESCE(sgs2.EDISID, us.EDISID) AS PrimaryEDISID, s.SiteID, s.Name,
		CASE
			WHEN Address3 = '' AND Address2 = '' THEN Address1
			WHEN Address3 = '' THEN Address2
			ELSE Address3
		END AS Town,
		s.PostCode,
		BDM.UserName AS BDM,
		s.SiteClosed
	FROM UserSites AS us
	LEFT JOIN (
		SELECT SiteGroupID,EDISID
		FROM SiteGroupSites AS s    
		LEFT JOIN SiteGroups AS sg
			ON s.SiteGroupID = sg.ID
		WHERE sg.TypeID = 1
	) AS sgs
		ON sgs.EDISID = us.EDISID
	LEFT JOIN SiteGroupSites AS sgs2
		ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
	JOIN Sites AS s
		ON s.EDISID = COALESCE(sgs2.EDISID, us.EDISID)
	-- Add named BDM for site
	JOIN 
		( SELECT us.EDISID, us.UserID, u.UserName
			FROM Users as u
			JOIN UserSites AS us
				ON u.ID = us.UserID
			WHERE UserType = 2
			) AS BDM
		ON BDM.EDISID = us.EDISID
		WHERE (us.UserID = @UserID OR @UserID IS NULL)
			AND (us.EDISID = @EDISID OR @EDISID IS NULL)
	
	-- Get most recent stock date
	DECLARE @LatestStockDate TABLE (
		EDISID INT,
		ProductID INT,
		LastStockDate DATE
	)			
	
	INSERT INTO @LatestStockDate
	SELECT DISTINCT md.EDISID, stk.ProductID, MAX(md.Date) OVER (PARTITION BY md.EDISID, stk.ProductID) AS LastStockDate
	FROM [dbo].[Stock] AS stk
	JOIN MasterDates AS md
		ON md.ID = stk.MasterDateID
	JOIN @MultiCellarSites AS s
		ON s.EDISID = md.EDISID
	
	-- Get earlier stock date for any site and product where there is no stock date in the report period
	DECLARE @RemainingStockDate AS TABLE (
		EDISID INT,
		ProductID INT,
		PreviousStockWeek DATE
	)
	
	INSERT INTO @RemainingStockDate
	SELECT DISTINCT md.EDISID, 
		stk.ProductID,
		-- Get week commencing date
		DATEADD(DAY, 1 - DATEPART(WEEKDAY, 
				MAX(md.Date) OVER (PARTITION BY md.EDISID, stk.ProductID)), 
			MAX(md.Date) OVER (PARTITION BY md.EDISID, stk.ProductID)
		) AS PreviousStockWeek
	FROM [dbo].[Stock] AS stk
	JOIN MasterDates AS md
		ON md.ID = stk.MasterDateID
	JOIN (SELECT *
			FROM @LatestStockDate AS lsd
			WHERE NOT lsd.LastStockDate BETWEEN @From AND @To
		) AS lsd
		ON lsd.EDISID = md.EDISID ANd lsd.ProductID = stk.ProductID
	WHERE md.Date < @From
	
	-- Get all products that have been referenced for a site
	;WITH [StockedProducts]
	AS (
		SELECT DISTINCT p.EDISID, p.Product, prd.Tied
		FROM (
			SELECT md.EDISID, md.Date, dld.Product
			FROM MasterDates AS md
			JOIN @MultiCellarSites AS s
				ON s.EDISID = md.EDISID
			JOIN DLData AS dld
				ON dld.DownloadID = md.ID

			UNION

			SELECT md.EDISID, md.Date, d.Product
			FROM MasterDates AS md
			JOIN @MultiCellarSites AS s
				ON s.EDISID = md.EDISID
			JOIN Delivery AS d
				ON d.DeliveryID = md.ID
			) AS p
		JOIN Products AS prd
			ON prd.ID = p.Product
	)

	
	SELECT 
		s.EDISID, 
		cal.FirstDateOfWeek AS WeekCommencing, 
		sp.Product AS ProductID,
		sp.Tied,		
		SUM(ISNULL(stk.Quantity, 0)) AS Stock, 
		SUM(ISNULL(dld.Quantity, 0)) AS Dispensed,  
		SUM(ISNULL(d.Quantity, 0)) * 8 As Delivered, -- Delivered stored as gallons - converting to pints
		( SUM(ISNULL(d.Quantity, 0)) - SUM(ISNULL(dld.Quantity, 0)) ) AS Variance
	INTO #Variance
	FROM MasterDates AS md
	JOIN Calendar AS cal
		ON cal.CalendarDate = md.Date		
	JOIN @MultiCellarSites AS s
		ON s.EDISID = md.EDISID
	JOIN StockedProducts AS sp
		ON sp.EDISID = md.EDISID
	LEFT JOIN @RemainingStockDate AS rsd
		ON rsd.EDISID = md.EDISID AND rsd.ProductID = sp.Product
	LEFT JOIN Stock AS stk
		ON stk.MasterDateID = md.ID AND stk.ProductID = sp.Product
	LEFT JOIN (						-- Get daily dispensed data per edisid and product
		SELECT dld.DownloadID, dld.Product, SUM(dld.Quantity) AS Quantity
		FROM DLData as dld
		GROUP BY dld.DownloadID, dld.Product
	) AS dld
		ON dld.DownloadID = md.ID AND dld.Product = sp.Product
	LEFT JOIN Delivery AS d
		ON d.DeliveryID = md.ID AND d.Product = sp.Product
	WHERE md.Date BETWEEN COALESCE(rsd.PreviousStockWeek, @From) AND @To
	GROUP BY s.EDISID, cal.FirstDateOfWeek, sp.Product, sp.Tied  
	
	-- Get latest BDM comments for each site
	;WITH [ManagerComment]
	AS (
		SELECT sc.EDISID,
			( scht.Description +  
				CASE sc.Text  
					WHEN NULL THEN ''
					ELSE ': ' + sc.Text
				END)  AS ManagerComment, sc.AddedOn, sc2.MaxDate
		FROM SiteComments AS sc
		JOIN SiteCommentHeadingTypes AS scht
			ON scht.ID = sc.HeadingType
		JOIN (
				SELECT sc.EDISID, MAX(sc.AddedOn) AS MaxDate
				FROM SiteComments AS sc
				WHERE sc.[Type] = 2
				GROUP BY sc.EDISID				
			) AS sc2
		ON sc2.EDISID = sc.EDISID
		WHERE sc.[Type] = 2
			AND sc.[AddedOn] = sc2.MaxDate
	),
	-- Get Latest Auditor Comment
	[AuditorComment]
	AS
	(
		SELECT sc.EDISID,
			(scht.Description +  
				CASE sc.Text  
					WHEN NULL THEN ''
					ELSE ': ' + sc.Text
				END) AS AuditorComment
		FROM SiteComments AS sc
		JOIN SiteCommentHeadingTypes AS scht
			ON scht.ID = sc.HeadingType
		JOIN (
				SELECT sc.EDISID, MAX(sc.AddedOn) AS MaxDate
				FROM SiteComments AS sc
				WHERE sc.[Type] = 1
				GROUP BY sc.EDISID				
			) AS sc2
		ON sc2.EDISID = sc.EDISID		
		WHERE sc.[Type] = 1
			AND sc.[AddedOn] = sc2.MaxDate
	),
	-- Get last stock date before report period
	[PreviousStockDate]			
	AS (
		SELECT DISTINCT md.EDISID, stk.ProductID, MAX(md.Date) OVER (PARTITION BY md.EDISID, stk.ProductID) AS PreviousStockDate
		FROM [dbo].[Stock] AS stk
		JOIN MasterDates AS md
			ON md.ID = stk.MasterDateID
		JOIN @MultiCellarSites AS s
			ON s.EDISID = md.EDISID
		WHERE md.Date < @From
	),
	-- Get all data since individual product stock dates, and calculate remaining stock
	[RemainingStock]
	AS
	(
		SELECT pcvi.EDISID, pcvi.ProductID, (SUM(pcvi.Stock) + SUM(Variance)) AS RemainingStock
		FROM #Variance AS pcvi
		JOIN @RemainingStockDate AS psd
			ON psd.EDISID = pcvi.EDISID AND psd.ProductID = pcvi.ProductID
		WHERE pcvi.WeekCommencing BETWEEN psd.PreviousStockWeek AND DATEADD(DAY, -1, @From)
		GROUP BY pcvi.EDISID, pcvi.ProductID
	),
	-- Get VRS Records
	[VRSRecords]
	AS
	(	
		SELECT vr.EDISID, vr.VisitDate, a.[Description]
		FROM VisitRecords AS vr
		JOIN (
			SELECT DISTINCT v.EDISID, MAX(v.VisitDate) OVER (PARTITION BY v.EDISID) AS LatestDate
			FROM VisitRecords AS v
		) AS vrDate
			ON vrDate.EDISID = vr.EDISID AND vrDate.LatestDate = vr.VisitDate
		JOIN @Admission AS a
			ON a.ID = vr.AdmissionID
		JOIN @MultiCellarSites as s
			ON s.EDISID = vr.EDISID
	),
	--Get Weekly status per site
	[TrafficLight]
	AS
	(
		SELECT	
			sr.EDISID,

		CASE 
			WHEN srt.Name = 'Red' THEN '#ff0000'
			WHEN srt.Name = 'Amber' THEN 'Orange'
			WHEN srt.Name = 'Green' THEN '#33cc33'
			WHEN srt.Name = 'Grey' THEN 'Gray'
			WHEN srt.Name = 'Blue' THEN 'Blue'
			ELSE '#ffffff'
		END AS HexColour

		FROM dbo.SiteRankings AS sr
			JOIN SiteRankingTypes as srt 
				ON srt.ID = sr.RankingTypeID
			JOIN (
					SELECT DISTINCT sr2.EDISID, Max(ValidFrom) OVER (PARTITION BY sr2.EDISID) AS LatestDate
					FROM SiteRankings AS sr2
				) AS LatestRanking
				ON LatestRanking.EDISID = sr.EDISID
			JOIN @MultiCellarSites as s
				ON s.EDISID = sr.EDISID
		WHERE sr.EDISID = LatestRanking.EDISID AND sr.ValidFrom = LatestRanking.LatestDate
	)

	

	-- ## MAIN QUERY ##
		SELECT 
		s.EDISID,
		s.PrimaryEDISID,
		s.SiteID, 
		s.Name, 
		s.Town, 
		s.PostCode, 
		s.BDM,
		s.SiteClosed,
		MAX(lsd.LastStockDate) OVER (PARTITION BY s.SiteID) AS LatestStockDate,
		MAX(psd.PreviousStockDate) OVER (PARTITION BY s.SiteID) AS PreviousStockDate,
		pcvi.WeekCommencing, 
		pcvi.Tied AS IsTied,
		SUM(pcvi.Delivered) AS Delivered, 
		SUM(pcvi.Dispensed) AS Dispensed, 
		SUM(pcvi.Variance) AS Variance,
		p.IsMetric,
		mc.ManagerComment,
		ac.AuditorComment,
		SUM(rs.RemainingStock) AS RemainingStock,
		vr.VisitDate,
		vr.Description,
		tl.HexColour
	FROM @MultiCellarSites AS s
	JOIN #Variance AS pcvi	-- Get Variance Data
		ON pcvi.EDISID = s.EDISID
	JOIN Products AS p							-- Get Metric data for the products
		ON p.ID = pcvi.ProductID
	JOIN [TrafficLight] as tl
		ON tl.EDISID = s.EDISID
	LEFT JOIN [ManagerComment] AS mc
		ON mc.EDISID = s.EDISID
	LEFT JOIN [AuditorComment] AS ac
		ON ac.EDISID = s.EDISID
	LEFT JOIN @LatestStockDate AS lsd
		ON lsd.EDISID = s.EDISID AND lsd.ProductID = pcvi.ProductID
	LEFT JOIN [PreviousStockDate] AS psd
		ON psd.EDISID = s.EDISID AND psd.ProductID = pcvi.ProductID
	LEFT JOIN  [RemainingStock] AS rs			
		ON rs.EDISID = s.EDISID AND rs.ProductID = pcvi.ProductID
	LEFT JOIN [VRSRecords] AS vr
		ON vr.EDISID = s.EDISID
	WHERE pcvi.WeekCommencing BETWEEN @From AND @To
	GROUP BY s.EDISID, s.PrimaryEDISID, s.SiteID, s.Name, s.Town, s.PostCode, s.BDM, s.SiteClosed, pcvi.WeekCommencing, pcvi.Tied, p.IsMetric, mc.ManagerComment, ac.AuditorComment, lsd.LastStockDate, psd.PreviousStockDate, vr.VisitDate, vr.Description, tl.HexColour


	DROP TABLE #Variance
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetReportPackRedAlert] TO PUBLIC
    AS [dbo];

