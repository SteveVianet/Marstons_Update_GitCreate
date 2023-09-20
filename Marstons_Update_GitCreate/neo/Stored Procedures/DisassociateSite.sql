CREATE PROCEDURE [neo].[DisassociateSite]
(
	@DatabaseID INT,
	@EDISID INT,
	@StatusID INT
)

AS

            --//1.remove from site groups
delete from SiteGroupSites
where EDISID = @EDISID
            --//2. update site dispense equipment --//3.update site status, region and area--//4.remove assigned auditor

DECLARE @BlankRegionID INT
DECLARE @BlankAreaID INT

SET @BlankRegionID = (SELECT TOP 1 ID 
from Regions
WHERE (LOWER(Description) LIKE '%none%' or Description = '')) --still a chance these could be null but shouldn't set to any other. just ensure tables have these options

SET @BlankAreaID = (SELECT ID 
from Areas
WHERE (LOWER(Description) LIKE '%none%' or Description = ''))--still a chance these could be null but shouldn't set to any other. just ensure tables have these options

update Sites
set EDISPassword = '', [Status] = @StatusID, EDISTelNo = '', SerialNo='', Version = '', SiteUser = '', Region = ISNULL(@BlankRegionID,0), AreaID = ISNULL(@BlankAreaID,0), Hidden = 1 
where EDISID = @EDISID           

EXEC [EDISSQL1\SQL1].[Auditing].dbo.UpdateSiteSerialNo @DatabaseID, @EDISID, ''

            --//5.remove users that aren't all sites users

Delete from UserSites 
WHERE UserID in (
select UserID
 from Users 
 join UserTypes on UserType = UserTypes.ID
 where AllSitesVisible = 0
) and EDISID = @EDISID

            --//6.remove site from schedules
DELETE FROM ScheduleSites
WHERE EDISID = @EDISID
GO
GRANT EXECUTE
    ON OBJECT::[neo].[DisassociateSite] TO PUBLIC
    AS [dbo];

