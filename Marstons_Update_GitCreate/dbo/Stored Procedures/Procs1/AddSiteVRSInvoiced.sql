
CREATE PROCEDURE [dbo].[AddSiteVRSInvoiced]
(
	@EDISID					INT,
	@ChargeDate				DATE,
	@Filename				VARCHAR(100) = NULL
)
AS

SET NOCOUNT ON

INSERT INTO dbo.SiteVRSInvoiced
(EDISID, ChargeDate, [Filename], ImportedOn, ImportedBy)
VALUES
(@EDISID, @ChargeDate, @Filename, GETDATE(), SUSER_NAME())

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteVRSInvoiced] TO PUBLIC
    AS [dbo];

