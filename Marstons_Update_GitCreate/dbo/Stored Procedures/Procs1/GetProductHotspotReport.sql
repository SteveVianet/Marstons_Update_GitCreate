CREATE PROCEDURE GetProductHotspotReport
	(
	@UserID		INT,
	@From		DATE,
	@To			DATE,
	@ProductID	VARCHAR(50)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET DATEFIRST 1 -- Set first day of the week to Monday

	-- Get multiple products into a table - could use STRING_SPLIT IN SQL Server 2016...
	DECLARE @Products TABLE (
		ProductID INT
	)

	DECLARE @temp VARCHAR(50) = @ProductID

	DECLARE @index INT = CHARINDEX(',', @temp)

	WHILE @index > 0
	BEGIN
		INSERT INTO @Products
		VALUES (SUBSTRING(@temp, 1, @index-1))

		SET @temp = SUBSTRING(@temp, @index+1, LEN(@temp)-@index)

		SET @index = CHARINDEX(',', @temp)
	END

	INSERT INTO @Products
		VALUES (@temp)
	

	-- Merge Multi-Cellar Sites
	DECLARE @Sites TABLE (
		EDISID INT,
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50)
	)

	INSERT INTO @Sites
	SELECT DISTINCT us.EDISID, s.SiteID, s.Name,
		CASE
			WHEN Address3 = '' AND Address2 = '' THEN Address1
			WHEN Address3 = '' THEN Address2
			ELSE Address3
		END AS Town
	FROM UserSites AS us
	LEFT JOIN (
		SELECT SiteGroupID,EDISID
		FROM SiteGroupSites AS s	
		LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
		WHERE sg.TypeID = 1
	) AS sgs
		ON sgs.EDISID = us.EDISID
	LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
	JOIN Sites AS s	ON s.EDISID = COALESCE(sgs2.EDISID, us.EDISID)
	WHERE us.UserID = @UserID

	DECLARE @RealData TABLE (
		PrimarySiteID INT,
		PrimarySiteName VARCHAR(50),
		Town VARCHAR(50),
		[Day] INT,
		[Shift] INT,
		Product INT,
		Quantity FLOAT	
		)

	INSERT INTO @RealData
	SELECT s.[PrimarySiteID], s.[PrimarySiteName], s.[Town],
		DATEPART(WEEKDAY, md.[Date]), 
		dld.[Shift],
		dld.Product,
		ROUND(SUM([Quantity]), 2) AS [Quantity]
	FROM @Sites AS s
	JOIN dbo.MasterDates AS md ON md.[EDISID] = s.[EDISID]
	JOIN dbo.DLData AS dld ON dld.[DownloadID] = md.[ID]
	WHERE md.[Date] BETWEEN @From AND @To
	AND dld.Product IN (SELECT * FROM @Products)
	GROUP BY s.[PrimarySiteID], s.[PrimarySiteName], s.[Town], DATEPART(WEEKDAY, md.[Date]), dld.Product, dld.[Shift]

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
		SELECT rd.PrimarySiteID, rd.PrimarySiteName, rd.Town
		FROM @RealData AS rd
		GROUP BY rd.PrimarySiteID, rd.PrimarySiteName, rd.Town
	) AS rd
	CROSS JOIN @Days AS d
	CROSS JOIN @Shifts AS s
	CROSS JOIN @Products AS p

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProductHotspotReport] TO PUBLIC
    AS [dbo];

