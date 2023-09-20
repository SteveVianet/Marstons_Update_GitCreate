CREATE PROCEDURE [dbo].[GetSiteSummaryReportByUser]
(
	@EDISID 	INT = NULL,
	@UserID		INT = NULL,
	@From 		SMALLDATETIME,
	@To 		SMALLDATETIME,
	@IncludeClosedSites BIT = NULL
)

AS

BEGIN
	SET DATEFIRST 1

	DECLARE @Sites TABLE (
		EDISID INT,
		PrimaryEDISD INT,
		PrimarySiteID VARCHAR(50),
		PrimarySiteName VARCHAR(50),
		Town  VARCHAR(50)
	)
 
	 INSERT INTO @Sites
		SELECT DISTINCT us.EDISID, s.EDISID, s.SiteID, s.Name,
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
		JOIN Sites AS s ON s.EDISID = COALESCE(sgs2.EDISID, us.EDISID)
		WHERE (us.UserID = @UserID OR @UserID IS NULL)
			AND (us.EDISID = @EDISID OR @EDISID IS NULL)

	SELECT 
		s.EDISID,
		s.PrimaryEDISD,
		s.PrimarySiteID,
		s.PrimarySiteName,
		s.Town,
		Locations.ID AS LocationID,
		Locations.Description AS Location,
		DLData.Pump,
		Products.Description AS Product,
		DATEPART(dw, md.[Date]) AS [WeekDay],
		SUM(DLData.Quantity) AS Dispensed
	FROM dbo.MasterDates As md
	JOIN @Sites AS s ON s.EDISID = md.EDISID
	JOIN dbo.DLData ON md.[ID] = DLData.DownloadID
	JOIN dbo.PumpSetup ON PumpSetup.Pump = DLData.Pump AND md.EDISID = PumpSetup.EDISID
	JOIN dbo.Locations ON Locations.[ID] = PumpSetup.LocationID
	JOIN dbo.Products ON Products.[ID] = PumpSetup.ProductID
	WHERE md.[Date] BETWEEN @From AND @To
		AND PumpSetup.ValidTo IS NULL
	GROUP BY s.EDISID, s.PrimaryEDISD,s.PrimarySiteID, s.PrimarySiteName, s.Town, Locations.ID, Locations.Description, DLData.Pump, Products.Description, DATEPART(dw, md.[Date])
	ORDER BY s.EDISID, s.PrimaryEDISD,s.PrimarySiteID, s.PrimarySiteName, s.Town, Locations.ID, DLData.Pump, Products.Description, DATEPART(dw, md.[Date])
	

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteSummaryReportByUser] TO PUBLIC
    AS [dbo];

