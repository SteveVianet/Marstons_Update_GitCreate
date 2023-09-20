CREATE PROCEDURE RawShiftData
	@ScheduleID INT,
	@From SMALLDATETIME,
	@To SMALLDATETIME,
	@ShowHidden BIT = 0
	
AS
BEGIN
	SET NOCOUNT ON;

	-- Taking into account for Multi Cellar
	DECLARE @Sites TABLE (
	EDISID INT,
	SiteID VARCHAR(50),
	Hidden BIT
	)

	INSERT INTO @Sites 

	SELECT DISTINCT ss.EDISID, s.SiteID, s.Hidden
	FROM ScheduleSites AS ss

		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s	
				LEFT JOIN SiteGroups AS sg ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs ON sgs.EDISID = ss.EDISID

		LEFT JOIN SiteGroupSites AS sgs2 ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		INNER JOIN Sites AS s ON s.EDISID = COALESCE(sgs2.EDISID, ss.EDISID)
	WHERE ss.ScheduleID = @ScheduleID

    --Main Select Query
	SELECT
		s.SiteID,	
		MD.[Date],
		DLData.Pump AS Font,
		DLData.[Shift],
		ROUND(DLData.Quantity,1) AS Volume,
		Products.[Description] AS Product
	FROM dbo.DLData
		INNER JOIN dbo.MasterDates AS MD ON MD.[ID] = DLData.DownloadID
		INNER JOIN @Sites AS s ON s.EDISID = MD.EDISID
		INNER JOIN ScheduleSites AS ss ON s.EDISID = ss.EDISID
		INNER JOIN dbo.Products ON Products.[ID] = DLData.Product
	WHERE ScheduleID = @ScheduleID
		AND(MD.[Date] >= @From) AND (MD.[Date] <= @To)
		AND (s.Hidden = 0 or @ShowHidden = 1)
	ORDER BY s.SiteID, MD.[Date]


END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RawShiftData] TO PUBLIC
    AS [dbo];

