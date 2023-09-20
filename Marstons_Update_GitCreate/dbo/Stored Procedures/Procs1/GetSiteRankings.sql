CREATE PROCEDURE [dbo].[GetSiteRankings]
(
	@EDISID	INT,
	@CategoryID	INT = NULL
)

AS

IF @CategoryID <= 10
BEGIN
	SELECT	ValidFrom,
		ValidTo,
		RankingTypeID,
		ManualText,
		AssignedBy,
		RankingCategoryID
	FROM dbo.SiteRankings
	WHERE EDISID = @EDISID AND (RankingCategoryID = @CategoryID OR @CategoryID IS NULL)
	ORDER BY ValidFrom
END
ELSE
BEGIN
	IF @CategoryID IS NULL 
	BEGIN
		DECLARE @FullRankings TABLE (ValidFrom SMALLDATETIME, ValidTo SMALLDATETIME, RankingTypeID INT NOT NULL, ManualText VARCHAR(1024) NOT NULL, AssignedBy VARCHAR(255) NOT NULL, RankingCategoryID INT NOT NULL)
		
		INSERT INTO @FullRankings
			(ValidFrom, ValidTo, RankingTypeID, ManualText, AssignedBy, RankingCategoryID)
		SELECT	ValidFrom,
			ValidTo,
			RankingTypeID,
			ManualText,
			AssignedBy,
			RankingCategoryID
		FROM dbo.SiteRankings
		WHERE EDISID = @EDISID AND (RankingCategoryID = @CategoryID OR @CategoryID IS NULL)
		ORDER BY ValidFrom
		
		/* Requires SQL 2005+ Compatibility
		INSERT INTO @FullRankings
			(ValidFrom, ValidTo, RankingTypeID, ManualText, AssignedBy, RankingCategoryID)
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(Ranking, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				Category AS RankingCategoryID
		FROM (	SELECT	EDISID, 
						TemperatureTL AS [11], 
						EquipmentRecircTL AS [12], 
						EquipmentAmbientTL AS [13], 
						ThroughputTL AS [14], 
						CleaningTL AS [15], 
						PouringYieldTL AS [16], 
						TillYieldTL AS [17]
				FROM SiteRankingCurrent) AS PivotRankings
		UNPIVOT (Ranking FOR Category IN 
				([11], [12], [13], [14], [15], [16], [17]))
		AS UnPivotRankings
		WHERE EDISID = @EDISID
		*/		

		/* The SQL 2000 way of doing the above */
		INSERT INTO @FullRankings
			(ValidFrom, ValidTo, RankingTypeID, ManualText, AssignedBy, RankingCategoryID)
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(TemperatureTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				11 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(EquipmentRecircTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				12 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(EquipmentAmbientTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				13 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(ThroughputTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				14 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(CleaningTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				15 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(PouringYieldTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				16 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		UNION
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				ISNULL(TillYieldTL, 6) AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				17 as RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
		
		SELECT ValidFrom, ValidTo, RankingTypeID, ManualText, AssignedBy, RankingCategoryID
		FROM @FullRankings
	END
	ELSE
	BEGIN 
		SELECT	CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) AS ValidFrom,
				CAST(DATEADD(day, 1, CAST(GETDATE() AS DATE)) AS SMALLDATETIME) AS ValidTo,
				CASE @CategoryID
				WHEN 11 THEN ISNULL(TemperatureTL, 6)
				WHEN 12 THEN ISNULL(EquipmentRecircTL, 6)
				WHEN 13 THEN ISNULL(EquipmentAmbientTL, 6)
				WHEN 14 THEN ISNULL(ThroughputTL, 6)
				WHEN 15 THEN ISNULL(CleaningTL, 6)
				WHEN 16 THEN ISNULL(PouringYieldTL, 6)
				WHEN 17 THEN ISNULL(TillYieldTL, 6)
				ELSE 6
				END AS RankingTypeID,
				'' AS ManualText,
				'' AS AssignedBy,
				@CategoryID AS RankingCategoryID
		FROM SiteRankingCurrent
		WHERE EDISID = @EDISID
	END
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRankings] TO PUBLIC
    AS [dbo];

