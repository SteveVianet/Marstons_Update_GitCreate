
CREATE PROCEDURE [dbo].[GetVRSInvoiced]
(
	@From		DATETIME,
	@To			DATETIME
)
AS

SELECT SiteVRSInvoiced.ID,
	   SiteVRSInvoiced.EDISID,
	   Sites.SiteID,
	   SiteVRSInvoiced.ChargeDate,
	   SiteVRSInvoiced.[Filename],
	   SiteVRSInvoiced.ImportedOn
FROM SiteVRSInvoiced
JOIN Sites ON Sites.EDISID = SiteVRSInvoiced.EDISID
WHERE SiteVRSInvoiced.ChargeDate BETWEEN @From AND @To
ORDER BY SiteVRSInvoiced.ChargeDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVRSInvoiced] TO PUBLIC
    AS [dbo];

