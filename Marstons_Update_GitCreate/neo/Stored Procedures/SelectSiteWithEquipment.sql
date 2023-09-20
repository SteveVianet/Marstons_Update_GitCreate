CREATE PROCEDURE [neo].[SelectSiteWithEquipment]
(
	@EDISID int
)

AS

select EDISID, SiteID, Name, Address1, PostCode, SystemTypes.Description as EDISType, ModemTypes.Description as ModemType, EDISTelNo, SerialNo
from Sites
join SystemTypes on SystemTypeID = SystemTypes.ID
join ModemTypes on ModemTypeID = ModemTypes.ID
Where Sites.EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[neo].[SelectSiteWithEquipment] TO PUBLIC
    AS [dbo];

