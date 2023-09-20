CREATE PROCEDURE GetShiftDataExportSheet
	@EDISID INT = NULL,
	@ScheduleID INT = NULL,
	@From DATE,
	@To DATE,
	@ShowWater BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --Get Multi-Cellar sites
	DECLARE @Sites TABLE (
	EDISID INT,
	IsPrimary BIT,
	PrimarySiteID VARCHAR(50),
	PrimarySiteName VARCHAR(50),
	Town  VARCHAR(50)
	)

	INSERT INTO @Sites
	SELECT DISTINCT ss.EDISID, sgs.IsPrimary, s.SiteID, s.Name,
		CASE
			WHEN Address3 = '' AND Address2 = '' THEN Address1
			WHEN Address3 = '' THEN Address2
			ELSE Address3
		END AS Town
	FROM ScheduleSites AS ss
	LEFT JOIN (
		SELECT SiteGroupID, EDISID, IsPrimary
		FROM SiteGroupSites AS s	
		LEFT JOIN SiteGroups AS sg
			ON s.SiteGroupID = sg.ID
		WHERE sg.TypeID = 1
	) AS sgs ON sgs.EDISID = ss.EDISID
	LEFT JOIN SiteGroupSites AS sgs2
		ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
	JOIN Sites AS s
		ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
	WHERE (ss.ScheduleID = @ScheduleID OR @ScheduleID IS NULL)
		AND (ss.EDISID = @EDISID OR @EDISID IS NULL)

	-- Generate days 
	DECLARE @Days TABLE ( [Day] INT ) 

	INSERT INTO @Days
	VALUES	(1), (2), (3), (4), (5), (6), (7)

	-- Generate shifts
	DECLARE @Shifts TABLE ( [Shift] INT )

	INSERT INTO @Shifts
	VALUES (1), (2), (3), (4), (5), (4), (6), (7), (8), (9), (10), (11), (12), 
		(13), (14), (15), (14), (16), (17), (18), (19), (20), (21), (22), (23), (24)

	IF @ShowWater = 1
		
		SELECT s.EDISID, s.IsPrimary, s.PrimarySiteID, s.PrimarySiteName, s.Town, md.[Date], sft.[Shift], ps.Pump, p.[Description], dld.Quantity, ws.Volume
		FROM @Sites AS s 
		JOIN MasterDates AS md ON md.EDISID = s.EDISID
		CROSS JOIN @Shifts AS sft
		JOIN PumpSetup AS ps ON (ps.ValidFrom <= md.Date AND (ps.ValidTo IS NULL OR ps.ValidTo >= md.[Date])) AND ps.EDISID = s.EDISID
		JOIN Products AS p ON p.ID = ps.ProductID	
		LEFT JOIN DLData AS dld ON dld.DownloadID = md.ID AND dld.[Shift] = sft.[Shift] AND dld.Pump = ps.Pump
		LEFT JOIN WaterStack AS ws ON ws.WaterID = md.ID AND DATEPART(HOUR, ws.Time) = sft.[Shift] - 1 AND ws.Line = ps.Pump
		WHERE md.Date BETWEEN @From AND @To		
		ORDER BY s.PrimarySiteID DESC, md.[Date], s.IsPrimary, ps.Pump, sft.[Shift]

	ELSE
		
		SELECT s.EDISID, s.IsPrimary, s.PrimarySiteID, s.PrimarySiteName, s.Town, md.[Date], sft.[Shift], ps.Pump, p.[Description], dld.Quantity, NULL AS Volume
		FROM @Sites AS s 
		JOIN MasterDates AS md ON md.EDISID = s.EDISID
		CROSS JOIN @Shifts AS sft
		JOIN PumpSetup AS ps ON (ps.ValidFrom <= md.Date AND (ps.ValidTo IS NULL OR ps.ValidTo >= md.[Date])) AND ps.EDISID = s.EDISID
		JOIN Products AS p ON p.ID = ps.ProductID	
		LEFT JOIN DLData AS dld ON dld.DownloadID = md.ID AND dld.[Shift] = sft.[Shift] AND dld.Pump = ps.Pump
		WHERE md.Date BETWEEN @From AND @To
		ORDER BY s.PrimarySiteID DESC, md.[Date], s.IsPrimary, ps.Pump, sft.[Shift]
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetShiftDataExportSheet] TO PUBLIC
    AS [dbo];

