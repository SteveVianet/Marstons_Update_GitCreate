CREATE PROCEDURE [dbo].[GetUserSitesInstallsByDate]
(
	@From		datetime,
	@To 		datetime,
	@UserID 	int
) 
AS

SET NOCOUNT ON

DECLARE @Installs TABLE 
(
	EDISID			int,
	SiteID			varchar(15),
	SiteName		varchar(60),
	SiteTown		varchar(60),
	SiteAddress		varchar(256),
	Postcode		varchar(10),
	CallStatus		varchar(1024),
	SupplementaryStatus	varchar(512),
	Comments		varchar(3072),
	BusinessManager	varchar(256),
	CompletedOn		datetime,
	WorkDetailComment	varchar(2048),
	PRIMARY KEY (EDISID)
)

INSERT INTO @Installs (EDISID, SiteID, SiteName, SiteTown, SiteAddress, Postcode, BusinessManager, CompletedOn)
	SELECT RelatedUserSites.EDISID, 
			SiteID, 
			Sites.Name,
			COALESCE(NULLIF(RTRIM(Sites.Address2), ''), 
				NULLIF(RTRIM(Sites.Address3), ''), 
				NULLIF(RTRIM(Sites.Address4), ''), 
				NULLIF(RTRIM(Sites.Address1), '?')),
			COALESCE(NULLIF(RTRIM(Sites.Address1) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address2) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address3) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address4), ''),''),
			Sites.PostCode,
			Users.UserName,
			c.ClosedOn			
	FROM (
    SELECT EDISID, MAX(RaisedOn) AS MaxDate
    FROM Calls c
    WHERE RaisedOn > @From
			AND c.CallTypeID = 2
    GROUP BY EDISID
	) x
	JOIN Calls c
		ON c.RaisedOn = x.MaxDate
	JOIN UserSites AS ParentUserSites
		ON ParentUserSites.EDISID = c.EDISID
	JOIN UserSites AS RelatedUserSites 
		ON RelatedUserSites.EDISID = ParentUserSites.EDISID
	JOIN Users 
		ON Users.[ID] = RelatedUserSites.UserID
	JOIN Sites
		ON Sites.EDISID = RelatedUserSites.EDISID
WHERE ParentUserSites.UserID = @UserID
	AND Users.UserType = 2
	AND Sites.Hidden = 0
	AND c.CallTypeID = 2


UPDATE @Installs SET CallStatus = cs.Description
	FROM (
    SELECT EDISID, MAX(ChangedOn) AS MaxDate
    FROM CallStatusHistory csh
			JOIN Calls AS c
				ON c.ID = csh.CallID
				AND c.CallTypeID = 2
    WHERE ChangedOn > @From
    GROUP BY EDISID
	) x
	JOIN CallStatusHistory csh
		ON csh.ChangedOn = x.MaxDate
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallStatuses cs
		ON cs.ID = csh.StatusID
	JOIN Calls AS c
		ON c.ID = csh.CallID
		AND c.CallTypeID = 2
	JOIN @Installs AS s
		ON s.EDISID = c.EDISID


UPDATE @Installs SET SupplementaryStatus = 'None'


UPDATE @Installs SET Comments = 
	COALESCE(dbo.udfConcatCallComments(cc.CallID, @From), '')
FROM 
	CallComments cc
	JOIN Calls AS c
		ON c.ID = cc.CallID
		AND c.CallTypeID = 2
	JOIN @Installs AS s
		ON s.EDISID = c.EDISID 


UPDATE @Installs SET WorkDetailComment = 
	COALESCE(dbo.udfConcatCallWorkDetailComments(cwdc.CallID, @From), '')
FROM 
	CallWorkDetailComments cwdc
	JOIN Calls AS c
		ON c.ID = cwdc.CallID
		AND CallTypeID = 2
	JOIN @Installs AS s
		ON s.EDISID = c.EDISID 

/*
UPDATE @Installs SET CompletedOn = c.ClosedOn
FROM (
    SELECT EDISID, MAX(VisitedOn) AS MaxDate
    FROM Calls
    WHERE CallTypeID = 2
    	AND ClosedOn < GETDATE()
    GROUP BY EDISID
	) x
	JOIN Calls c 
		ON x.EDISID = c.EDISID
		AND x.MaxDate = c.ClosedOn
		AND CallTypeID = 2
	JOIN @Installs AS Installs
		ON Installs.EDISID = c.EDISID
*/

SELECT EDISID, SiteID, SiteName, SiteTown, SiteAddress, Postcode, CallStatus, SupplementaryStatus, Comments, BusinessManager, CompletedOn, WorkDetailComment FROM @Installs ORDER BY SiteName, BusinessManager, EDISID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesInstallsByDate] TO PUBLIC
    AS [dbo];

