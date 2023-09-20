CREATE PROCEDURE RedAlert
	@ScheduleID INT = NULL,
	@EDISID INT = NULL,
	@From SMALLDATETIME,
	@To SMALLDATETIME,
	@ShowHidden BIT = 0
	
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

	--Get OD for each site
	DECLARE @OD TABLE	( 
		ID INT,
		UserName VARCHAR(30),
		EDISID INT
			)

	INSERT INTO @OD
	SELECT u.ID,
		u.UserName,
		s.EDISID
	FROM Users As u
		INNER JOIN UserSites as us ON us.UserID = u.ID
		INNER JOIN Sites AS s ON s.EDISID = us.EDISID
	WHERE u.UserType = '1' and us.EDISID = s.EDISID

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

	--Get Auditor Comment

	DECLARE @Comments TABLE(
		EDISID INT,
		AuditorComment VARCHAR(2000)
		)

	INSERT INTO @Comments
	SELECT ss.EDISID,
		(CONVERT(VARCHAR(20),[Date],106)+': ' + scht.[Description] +': '+ [Text]) AS AuditiorComment
	FROM dbo.SiteComments as sc
		INNER JOIN SiteCommentHeadingTypes AS scht ON scht.ID = sc.HeadingType
		LEFT JOIN Sites AS s ON sc.EDISID = s.EDISID
		LEFT JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE 
		 ([Type] = 1)
		AND [AddedOn] = (SELECT MAX([AddedOn]) FROM SiteComments AS sc2 WHERE sc2.EDISID = sc.EDISID AND [Type]=1)
	ORDER BY [Date] DESC

	--Get Manager Comment

	DECLARE @CommentsManager TABLE(
		EDISID INT,
		ManagerComment VARCHAR(2000)
		)

	INSERT INTO @CommentsManager
	SELECT ss.EDISID,
		(CONVERT(VARCHAR(20),[Date],106)+': ' + [Text]) AS ManagerComment
	FROM dbo.SiteComments as sc
		INNER JOIN SiteCommentHeadingTypes AS scht ON scht.ID = sc.HeadingType
		LEFT JOIN Sites AS s ON sc.EDISID = s.EDISID
		LEFT JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE 
		 ([Type] = 2)
		AND [AddedOn] = (SELECT MAX([AddedOn]) FROM SiteComments AS sc2 WHERE sc2.EDISID = sc.EDISID AND [Type]=2)
	ORDER BY [Date] DESC

	--Get Tampering Date

	DECLARE @Tampering TABLE(
		EDISID INT,
		TamperComment VARCHAR(20)
		)

	INSERT INTO @Tampering
	SELECT ss.EDISID,
		   (CONVERT(VARCHAR(20),sc.[Date],106)+': ' + [Text]) AS TamperingComment
	FROM dbo.SiteComments as sc
		INNER JOIN SiteCommentHeadingTypes AS scht ON scht.ID = sc.HeadingType
		LEFT JOIN Sites AS s ON sc.EDISID = s.EDISID
		left JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
	WHERE 
		([Type] = 8)
		AND [AddedOn] = (SELECT MAX([AddedOn]) FROM SiteComments AS sc2 WHERE sc2.EDISID = sc.EDISID AND [Type]=8 AND [AddedOn] BETWEEN @From AND DATEADD("d", 6, @To))
	ORDER BY [Date] DESC

	

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
		SELECT	
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
			INNER JOIN SiteRankingTypes as srt ON srt.ID = sr.RankingTypeID
			LEFT JOIN Sites AS s ON sr.EDISID = s.EDISID
			LEFT JOIN (SELECT DISTINCT EDISID
					FROM ScheduleSites AS ss
					WHERE (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (ss.EDISID = @EDISID or @EDISID IS NULL)
					 )AS ss ON s.EDISID = ss.EDISID
		WHERE ValidFrom = (SELECT Max(ValidFrom) FROM SiteRankings AS sr2 WHERE sr2.EDISID = sr.EDISID)
		ORDER BY EDISID, ValidFrom desc

	-- Taking into account for Multi Cellar

	DECLARE @Sites TABLE (
		EDISID INT,
		SiteID VARCHAR(50),
		Name VARCHAR(50),
		Address1 VARCHAR(50),
		Address2 VARCHAR(50),
		Address3 VARCHAR(50),
		SiteOnline SMALLDATETIME,
		Hidden BIT
		)

	INSERT INTO @Sites

	SELECT DISTINCT ss.EDISID, s.SiteID, s.Name, s.Address1, s.Address2,s.Address3,s.SiteOnline,s.Hidden
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

	SELECT
		ISNULL(OD.UserName,'None') AS OD,
		ISNULL(BDM.UserName,'None') AS BDM,
		s.SiteID,
		s.Name,
		CASE 
			WHEN s.Address3 = '' AND s.Address2 = '' THEN s.Address1
			WHEN s.Address3 = '' THEN s.Address2
			ELSE s.Address3
		END AS Town,

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

		ISNULL(comments.AuditorComment,'') AS AuditorComment,
		ISNULL(CommentsManager.ManagerComment,'') AS ManagerComment,
		ISNULL(t.TamperComment, '') AS Tampering,

		ISNULL(stl.HexColour,'#ffffff') AS TrafficLightColour
	FROM @Sites AS s
		LEFT JOIN ScheduleSites AS ss On s.EDISID = ss.EDISID
		LEFT JOIN @dispensed AS d ON s.EDISID = d.EDISID
		LEFT JOIN @delivered AS del ON s.EDISID = del.EDISID
		LEFT JOIN UserSites AS us ON s.EDISID = us.EDISID
		LEFT JOIN @BDM as BDM ON us.EDISID = BDM.EDISID
		LEFT JOIN @OD AS OD ON us.EDISID = OD.EDISID
		LEFT JOIN @UntiedDispensed AS ud ON s.EDISID = ud.EDISID
		LEFT JOIN @UntiedDelivered AS udel ON s.EDISID = udel.EDISID
		LEFT JOIN @Comments AS comments ON s.EDISID = comments.EDISID
		LEFT JOIN @CommentsManager AS CommentsManager ON s.EDISID = CommentsManager.EDISID
		LEFT JOIN @Tampering AS t ON s.EDISID = t.EDISID
		LEFT JOIN @SiteTrafficLights AS stl ON s.EDISID = stl.EDISID
	WHERE (s.Hidden = 0 or @ShowHidden = 1) AND (ss.ScheduleID = @ScheduleID or @ScheduleID IS NULL) AND (s.EDISID = @EDISID or @EDISID IS NULL)
	GROUP BY s.SiteID, s.Name,s.Address1,s.Address2,s.Address3,s.SiteOnline,d.Dispensed,del.Delivered,BDM.UserName, OD.UserName, ud.Dispensed, udel.Delivered,comments.AuditorComment, CommentsManager.ManagerComment,t.TamperComment, stl.HexColour, s.EDISID
	ORDER BY Variance

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RedAlert] TO PUBLIC
    AS [dbo];

