
CREATE PROCEDURE [dbo].[GetSiteExceptionEmailAddresses]
(
	@EDISID		INT,
	@AlertMode	BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT)
DECLARE @SiteGroupID INT

INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

SELECT LOWER(EMail) AS Email
FROM Users
JOIN UserSites ON UserSites.UserID = Users.ID AND UserSites.EDISID IN (SELECT EDISID FROM @Sites)
WHERE EMail <> ''
AND UserType IN (5, 6)
AND WebActive = 1
AND Deleted = 0
AND (LastWebsiteLoginDate >= DATEADD(DAY, -90, GETDATE()) OR NeverExpire = 1)
--AND DetailsReviewedOn IS NOT NULL
AND ((@AlertMode = 0 AND DetailsReviewedOn IS NOT NULL) OR (@AlertMode = 1 AND (SendEMailAlert = 1 OR DetailsReviewedOn IS NOT NULL)))
GROUP BY LOWER(EMail)

UNION

SELECT LOWER(Email) AS Email
FROM SiteExceptionEmailAddresses
WHERE EDISID IN (SELECT EDISID FROM @Sites)
--AND @AlertMode = 0
GROUP BY LOWER(Email)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteExceptionEmailAddresses] TO PUBLIC
    AS [dbo];

