CREATE PROCEDURE [dbo].[GetSiteHotspotReportByUser]
	(
	@UserID		INT,
	@From			DATE,
	@To				DATE,
	@IncludeClosedSites BIT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET DATEFIRST 1 -- Set first day of the week to Monday

	-- Merge Multi-Cellar Sites
	DECLARE @Sites TABLE (
		EDISID INT,
		PrimaryEDISD INT,
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town  VARCHAR(50),
		BDM  VARCHAR(50)
	)

	INSERT INTO @Sites

		SELECT DISTINCT us.EDISID, s.EDISID, s.SiteID, s.Name,
			CASE
				WHEN Address3 = '' AND Address2 = '' THEN Address1
				WHEN Address3 = '' THEN Address2
				ELSE Address3
			END AS Town,
			BDM.UserName
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
		JOIN ( SELECT us.EDISID, u.UserName
				FROM UserSites AS us
				JOIN Users AS u
					ON u.ID = us.UserID
				WHERE u.UserType = 2	-- Get BDM's only
		) AS BDM
			ON BDM.EDISID = s.EDISID	
		WHERE us.UserID = @UserID
			AND (@IncludeClosedSites = 1 OR s.SiteClosed = 0)

	DECLARE @RealData TABLE (
		EDISID INT,
		PrimaryEDISID INT,
		PrimarySiteID INT,
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		BDM VARCHAR(50),
		[Day] INT,
		[Shift] INT,
		Quantity FLOAT	
		)

	INSERT INTO @RealData
	SELECT s.EDISID, s.PrimaryEDISD, s.[PrimarySiteID], s.[PrimarySiteName], s.[Town], s.BDM,
		DATEPART(WEEKDAY, md.[Date]), 
		dld.[Shift],
		ROUND(SUM([Quantity]), 2) AS [Quantity]
	FROM @Sites AS s
	JOIN dbo.MasterDates AS md ON md.[EDISID] = s.[EDISID]
	JOIN dbo.DLData AS dld ON dld.[DownloadID] = md.[ID]
	WHERE md.[Date] BETWEEN @From AND @To
	GROUP BY s.EDISID, s.PrimaryEDISD, s.[PrimarySiteID], s.[PrimarySiteName], s.[Town], s.BDM, DATEPART(WEEKDAY, md.[Date]), dld.[Shift]

	--Need to merge in zero quantity data so report headers show up...
	
	-- Generate days 
	DECLARE @Days TABLE ( [Day] INT ) 

	INSERT INTO @Days
	VALUES	(1), (2), (3), (4), (5), (6), (7)

	-- Generate shifts
	DECLARE @Shifts TABLE ( [Shift] INT )

	INSERT INTO @Shifts
	VALUES (1), (2), (3), (4), (5), (4), (6), (7), (8), (9), (10), (11), (12), 
		(13), (14), (15), (14), (16), (17), (18), (19), (20), (21), (22), (23), (24)

	
	SELECT * FROM @RealData
	UNION ALL
	SELECT *,
		0 AS Quantity
	FROM (
		SELECT rd.EDISID, rd.PrimaryEDISID, rd.PrimarySiteID, rd.PrimarySiteName, rd.Town, rd.BDM
		FROM @RealData AS rd
		GROUP BY rd.EDISID, rd.PrimaryEDISID,  rd.PrimarySiteID, rd.PrimarySiteName, rd.Town, rd.BDM
	) AS rd
	CROSS JOIN @Days AS d
	CROSS JOIN @Shifts AS s

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteHotspotReportByUser] TO PUBLIC
    AS [dbo];

