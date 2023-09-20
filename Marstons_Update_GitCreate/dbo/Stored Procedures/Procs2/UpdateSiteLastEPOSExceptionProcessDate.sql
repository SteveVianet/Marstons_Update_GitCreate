
CREATE PROCEDURE dbo.UpdateSiteLastEPOSExceptionProcessDate
(
	@EDISID							INT = NULL,
	@LastEPOSExceptionProcessDate	DATETIME
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT)
DECLARE @SiteGroupID INT

-- Find out which EDISIDs are relevant (plough through SiteGroups)
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

UPDATE Sites
SET LastEPOSExceptionProcessDate = @LastEPOSExceptionProcessDate
WHERE (EDISID IN (SELECT EDISID FROM @Sites) OR @EDISID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastEPOSExceptionProcessDate] TO PUBLIC
    AS [dbo];

