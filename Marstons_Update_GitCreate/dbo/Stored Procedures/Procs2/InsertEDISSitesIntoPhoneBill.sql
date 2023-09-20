CREATE PROCEDURE dbo.InsertEDISSitesIntoPhoneBill 
(
	@DatabaseID		INT
)
AS

INSERT INTO [SQL1\SQL1].PhoneBill.dbo.LandlineEDIS
SELECT Sites.EDISID AS EDISID, 
               REPLACE(Sites.EDISTelNo, ' ', '') AS TelephoneNumber,
               Sites.Name As SiteName, 
               Sites.TenantName As Owner,
               Sites.PostCode As Postcode,
               MIN([Date]) AS MinDispensedDate, 
               MAX([Date]) AS MaxDispensedDate,
	 Sites.SiteID As SiteID,
	@DatabaseID As DatabaseID
FROM MasterDates
JOIN Sites ON MasterDates.EDISID = Sites.EDISID
WHERE Sites.Hidden = 0 AND Sites.EDISTelNo <> ''
GROUP BY Sites.EDISID, Sites.EDISTelNo, Sites.Name, Sites.TenantName, Sites.PostCode, Sites.SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertEDISSitesIntoPhoneBill] TO PUBLIC
    AS [dbo];

