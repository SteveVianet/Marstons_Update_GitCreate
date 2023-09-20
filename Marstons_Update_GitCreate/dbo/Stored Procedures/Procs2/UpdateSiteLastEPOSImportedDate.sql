
CREATE PROCEDURE dbo.UpdateSiteLastEPOSImportedDate
(
	@SiteID					VARCHAR(100),
	@LastEPOSImportedDate	DATETIME
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @Sites TABLE(EDISID INT)
DECLARE @SiteGroupID INT

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID

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
SET LastEPOSImportedDate = @LastEPOSImportedDate
WHERE EDISID IN (SELECT EDISID FROM @Sites)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastEPOSImportedDate] TO PUBLIC
    AS [dbo];

