CREATE PROCEDURE GetLineCleanEfficiencyReportByUser 
	@UserID Int,
	@From DATE,
	@To DATE,
	@ExcludeClosedSites BIT,
	@ShowHidden BIT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @UserHasAllSites BIT

	SELECT @UserHasAllSites = AllSitesVisible
	FROM UserTypes AS ut
	JOIN Users AS u
		ON u.[UserType] = ut.[ID]
	WHERE u.[ID] = @UserID

	--Table of BDMs assigned to a site
		
	DECLARE @SitesBDM_OD TABLE (
		EDISID INT,
		SiteID VARCHAR(20), 
		Name VARCHAR(100),
		OwnerID VARCHAR(50),
		Location VARCHAR(50),
		BDM_ID INT,
		BDMName VARCHAR(100),
		OD_ID INT,
		ODName VARCHAR(100)
		)

	INSERT INTO @SitesBDM_OD ( EDISID, SiteID, Name, OwnerID, Location, BDM_ID, BDMName, OD_ID, ODName)
	SELECT s.EDISID, 
		s.SiteID, 
		s.Name,
		s.OwnerID,
		CASE
			WHEN Address3 = '' AND Address2 = '' THEN Address1
			WHEN Address3 = '' THEN Address2
			ELSE Address3
		END AS Location,
		BDM.UserID, 
		BDM.UserName, 
		OD.UserID, 
		OD.UserName	
	FROM Sites as s
	JOIN UserSites AS us
		ON s.EDISID = us.EDISID
	-- Add named BDM for site
	JOIN 
		( SELECT us.EDISID, us.UserID, u.UserName
			FROM Users as u
			JOIN UserSites AS us
				ON u.ID = us.UserID
			WHERE UserType = 2
			) AS BDM
		ON BDM.EDISID = us.EDISID
	-- Add named OD for site
	JOIN 
		( SELECT us.EDISID, us.UserID, u.UserName
			FROM Users as u
			JOIN UserSites AS us
				ON u.ID = us.UserID
			WHERE UserType = 1
			) AS OD
		ON OD.EDISID = us.EDISID
		--Display only User's sites or all sites
	WHERE (us.UserID = @UserID OR @UserHasAllSites = 1)
		-- Should closed sites be displayed?
		AND ( s.SiteClosed = 0 OR @ExcludeClosedSites = 0 )
		--Should Hidden sites be displayed?
		AND ( s.Hidden = 0 OR @ShowHidden = 1 )

	SELECT
		s.SiteID,
		s.Name,
		s.Location,
		s.BDMName,
		s.ODName,
		ISNULL(TotalDispense, 0) AS TotalDispense,
		ISNULL(OverdueDispense, 0) AS OverdueDispense,
		CASE TotalDispense 
			When 0 Then -1
			ELSE OverdueDispense / TotalDispense
		END AS OverduePercentage, 
		[Date] AS ReportDate,
		o.CleaningAmberPercentTarget AS AmberLevel,
		o.CleaningRedPercentTarget AS RedLevel
	FROM @SitesBDM_OD AS s
	JOIN Owners as o ON s.OwnerID = o.ID
	LEFT JOIN (
		SELECT EDISID,
			SUM(PCCDispense.TotalDispense) AS TotalDispense,
			SUM(PCCDispense.OverdueCleanDispense) AS OverdueDispense,
			PCCDispense.[Date]
		FROM PeriodCacheCleaningDispense AS PCCDispense
		JOIN ProductCategories 
				ON ProductCategories.ID = PCCDispense.CategoryID
				AND ProductCategories.IncludeInLineCleaning = 1
		-- The manipulation of the 'From' and 'To' date is because users select the beginning Monday of the week they are interested in,
		-- but the data for that week isn't generated until the following Monday.
		WHERE PCCDispense.[Date] BETWEEN @From AND @To
		GROUP BY EDISID, [Date]
			) AS Percentage ON Percentage.EDISID = s.EDISID			
	ORDER By [Date] ASC, s.SiteID

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLineCleanEfficiencyReportByUser] TO PUBLIC
    AS [dbo];

