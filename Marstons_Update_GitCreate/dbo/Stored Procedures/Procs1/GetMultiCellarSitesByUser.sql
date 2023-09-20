CREATE PROCEDURE GetMultiCellarSitesByUser
	(
		@UserID INT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT DISTINCT us.EDISID, s.SiteID, s.Name,
			CASE
				WHEN Address3 = '' AND Address2 = '' THEN Address1
				WHEN Address3 = '' THEN Address2
				ELSE Address3
			END AS Town,
			s.PostCode,
			BDM.UserName AS BDM,
			s.SiteClosed
		FROM UserSites AS us
		-- Add Site Group ID if applicable
		LEFT JOIN (
			SELECT SiteGroupID,EDISID
			FROM SiteGroupSites AS s    
			LEFT JOIN SiteGroups AS sg
				ON s.SiteGroupID = sg.ID
			WHERE sg.TypeID = 1
		) AS sgs
			ON sgs.EDISID = us.EDISID
		-- Add Primary Site for Group
		LEFT JOIN SiteGroupSites AS sgs2
			ON sgs2.SiteGroupID = sgs.SiteGroupID AND sgs2.IsPrimary = 1
		-- Add EDISID for Primary site
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
			WHERE (us.UserID = @UserID)
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetMultiCellarSitesByUser] TO PUBLIC
    AS [dbo];

