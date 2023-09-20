
CREATE PROCEDURE GetEmailExceptionCountByUser
	@UserID		INT,
	@From		DATETIME,
	@To			DATETIME
AS

SET NOCOUNT ON;

DECLARE @UserSites TABLE(EDISID INT NOT NULL)
DECLARE @Sites TABLE(EDISID INT NOT NULL, CellarID INT NOT NULL IDENTITY)
DECLARE @SiteGroupID INT
DECLARE @SiteOnline DATETIME

INSERT INTO @UserSites (EDISID)
SELECT s.EDISID FROM Sites s
INNER JOIN UserSites us ON us.EDISID = s.EDISID
WHERE us.UserID = @UserID

SELECT @SiteOnline = SiteOnline
FROM dbo.Sites
WHERE EDISID IN (SELECT EDISID FROM @UserSites)

-- Find out which EDISIDs are relevant (plough through SiteGroups)
INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM Sites
WHERE EDISID IN (SELECT EDISID FROM @UserSites)
 
SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID IN (SELECT EDISID FROM @UserSites)
 
INSERT INTO @Sites (EDISID)
SELECT SiteGroupSites.EDISID
FROM SiteGroupSites
JOIN Sites ON Sites.EDISID = SiteGroupSites.EDISID
WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID NOT IN (SELECT EDISID FROM @UserSites)

SELECT COUNT(*) AS 'SiteExceptions'
FROM SiteExceptions se
WHERE se.ExceptionEmailID IS NOT NULL
	AND se.EDISID IN (SELECT EDISID FROM @Sites)
	AND se.TradingDate BETWEEN @From AND @To


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetEmailExceptionCountByUser] TO PUBLIC
    AS [dbo];

