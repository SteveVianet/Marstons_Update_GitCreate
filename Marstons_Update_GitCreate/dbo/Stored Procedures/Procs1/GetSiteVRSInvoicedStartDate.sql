
CREATE PROCEDURE [dbo].[GetSiteVRSInvoicedStartDate]
(
	@EDISID		INT,
	@From		DATE,
	@To			DATE
)
AS

SET NOCOUNT ON

SELECT ChargeDate
FROM SiteVRSInvoiced
WHERE EDISID = @EDISID
AND ChargeDate BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteVRSInvoicedStartDate] TO PUBLIC
    AS [dbo];

