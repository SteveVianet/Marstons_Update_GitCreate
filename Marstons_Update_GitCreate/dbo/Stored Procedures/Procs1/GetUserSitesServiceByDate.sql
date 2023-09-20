CREATE PROCEDURE [dbo].[GetUserSitesServiceByDate]
(
	@From		datetime,
	@To		datetime,
	@UserID	int
)
AS

SET NOCOUNT ON

DECLARE @Service TABLE
(
	EDISID			int,
	SiteID			varchar(15),
	SiteName		varchar(60),
	SiteAddress		varchar(256),
	Postcode		varchar(10),
	FaultSalesReference	varchar(512),
	CallStatus		varchar(256),
	VisitedOn		datetime,
	Comments		varchar(4000),
	BusinessManager	varchar(256),
	WorkDetailComment	varchar(2048)
	PRIMARY KEY (EDISID)
)


INSERT INTO @Service (EDISID, SiteID, SiteName, SiteAddress, Postcode, BusinessManager)
	SELECT RelatedUserSites.EDISID, 
			SiteID, 
			Sites.Name, 
			COALESCE(NULLIF(RTRIM(Sites.Address1) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address2) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address3) + ', ', ', '),'') +
				COALESCE(NULLIF(RTRIM(Sites.Address4), ''),''),
			Sites.PostCode,
			Users.UserName
	FROM (
    SELECT EDISID, MAX(RaisedOn) AS MaxDate
    FROM Calls c
    WHERE RaisedOn > @From
			AND c.CallTypeID = 1
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
	AND c.CallTypeID = 1

UPDATE @Service SET FaultSalesReference = 
	COALESCE(dbo.udfConcatCallFaults(cf.CallID), '')
FROM CallFaults cf
	JOIN Calls AS c
		ON c.ID = cf.CallID
	JOIN @Service AS s
		ON s.EDISID = c.EDISID
WHERE c.CallTypeID = 1
	

UPDATE @Service SET CallStatus = cs.Description
	FROM (
    SELECT EDISID, MAX(ChangedOn) AS MaxDate
    FROM CallStatusHistory csh
			JOIN Calls AS c
				ON c.ID = csh.CallID
    WHERE ChangedOn > @From
			AND c.CallTypeID = 1
    GROUP BY EDISID
	) x
	JOIN CallStatusHistory csh
		ON csh.ChangedOn = x.MaxDate
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallStatuses cs
		ON cs.ID = csh.StatusID
	JOIN Calls AS c
		ON c.ID = csh.CallID
	JOIN @Service AS s
		ON s.EDISID = c.EDISID
WHERE c.CallTypeID = 1


UPDATE @Service SET VisitedOn = c.VisitedOn
FROM (
    SELECT EDISID, MAX(VisitedOn) AS MaxDate
    FROM Calls
    WHERE CallTypeID = 1
    AND VisitedOn < GETDATE()
    GROUP BY EDISID
	) x
	JOIN Calls c
		ON x.EDISID = c.EDISID
		AND x.MaxDate = c.VisitedOn
		AND CallTypeID = 1
	JOIN @Service AS Service
		ON Service.EDISID = c.EDISID

UPDATE @Service
SET VisitedOn = '1900-01-01'
WHERE VisitedOn IS NULL

UPDATE @Service SET Comments = 
	COALESCE(dbo.udfConcatCallComments(cc.CallID, @From), '')
FROM 
	CallComments cc
	JOIN Calls AS c
		ON c.ID = cc.CallID
		AND c.CallTypeID = 1
	JOIN @Service AS s
		ON s.EDISID = c.EDISID 


UPDATE @Service SET WorkDetailComment = 
	COALESCE(dbo.udfConcatCallWorkDetailComments(cwdc.CallID, @From), '')
FROM 
	CallWorkDetailComments cwdc
	JOIN Calls AS c
		ON c.ID = cwdc.CallID
		AND c.CallTypeID = 1
	JOIN @Service AS s
		ON s.EDISID = c.EDISID 


SELECT EDISID, SiteID, SiteName, SiteAddress, Postcode, FaultSalesReference, CallStatus, VisitedOn, ISNULL(Comments,'') AS [Comments], BusinessManager, WorkDetailComment
FROM @Service 
ORDER BY SiteName, BusinessManager, EDISID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetUserSitesServiceByDate] TO PUBLIC
    AS [dbo];

