CREATE PROCEDURE [dbo].[GetSiteLastImportedEndDate]
(
	@EDISID				    INT,
	@ShowSiteGroupSites	    BIT = 0,
    @ExcludeHiddenCellars   BIT = 1
)
AS

SET NOCOUNT ON

--DECLARE	@EDISID				INT = 5
--DECLARE	@ShowSiteGroupSites	BIT = 1

DECLARE @GroupID INT
SELECT @GroupID = SiteGroupID FROM SiteGroupSites WHERE EDISID = @EDISID

--SELECT SiteGroupSites.*, Sites.[Hidden] FROM SiteGroupSites JOIN Sites ON SiteGroupSites.EDISID = Sites.EDISID
--WHERE SiteGroupSites.SiteGroupID = @GroupID

IF @ShowSiteGroupSites = 1
BEGIN
	DECLARE @Sites TABLE(EDISID INT)
	DECLARE @SiteGroupID INT

	INSERT INTO @Sites (EDISID)
	SELECT @EDISID AS EDISID

	SELECT @SiteGroupID = SiteGroupID
	FROM SiteGroupSites
	JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
	WHERE TypeID = 1 AND EDISID = @EDISID

	INSERT INTO @Sites
	(EDISID)
	SELECT SiteGroupSites.EDISID
	FROM SiteGroupSites
    JOIN Sites ON SiteGroupSites.EDISID = Sites.EDISID
	WHERE SiteGroupSites.SiteGroupID = @SiteGroupID AND SiteGroupSites.EDISID <> @EDISID
    AND (@ExcludeHiddenCellars = 0 OR Sites.[Hidden] = 0)

	SELECT ISNULL(LastImportedEndDate, '1899-12-30') AS LastImportedEndDate
    --SELECT *
	FROM Sites
	WHERE EDISID IN (SELECT EDISID FROM @Sites)

END
ELSE
BEGIN
	SELECT ISNULL(LastImportedEndDate, '1899-12-30') AS LastImportedEndDate
    --SELECT *
	FROM Sites
	WHERE EDISID = @EDISID

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteLastImportedEndDate] TO PUBLIC
    AS [dbo];

