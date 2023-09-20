CREATE FUNCTION fnGetMultiCellarSites
(
	@UserID INT = NULL,
	@ScheduleID INT = NULL,
	@SiteID VARCHAR(50) = NULL	
)
RETURNS 
@MultiCellarSites TABLE 
(
	EDISID INT,
	PrimaryEDISID INT,
	SiteID VARCHAR(50),
	Name VARCHAR(50),
	Town VARCHAR(50),
	PostCode VARCHAR(50),
	BDM VARCHAR(50),
	SiteOnline DATE,
	SiteClosed BIT
)
AS
BEGIN

	DECLARE @Sites TABLE (EDISID INT)

	IF @ScheduleID != 0	
	BEGIN
		INSERT INTO @Sites
		SELECT DISTINCT EDISID FROM ScheduleSites ss WHERE (ss.ScheduleID = @ScheduleID)
	END

	ELSE IF @UserID != 0
		BEGIN
			INSERT INTO @Sites
			SELECT DISTINCT EDISID FROM UserSites WHERE (UserID = @UserID)
		END

	ELSE IF @SiteID != 0
		BEGIN
			INSERT INTO @Sites
			SELECT EDISID FROM Sites s WHERE (SiteID = @SiteID)
	END

	INSERT INTO @MultiCellarSites 
	SELECT DISTINCT 
		us.EDISID
		, COALESCE(sgs2.EDISID, us.EDISID) AS PrimaryEDISID
		, s.SiteID
		, s.Name
		, CASE
			WHEN us.Address3 = '' AND us.Address2 = '' THEN us.Address1
			WHEN us.Address3 = '' THEN us.Address2
			ELSE us.Address3
		END AS Town,s.PostCode
		,BDM.UserName AS BDM
		,s.SiteOnline
		,s.SiteClosed
	FROM Sites AS us
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
		WHERE us.EDISID IN (SELECT * FROM @Sites)
	
	RETURN 
END