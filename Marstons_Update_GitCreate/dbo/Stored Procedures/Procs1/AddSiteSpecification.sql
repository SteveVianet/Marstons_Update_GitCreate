
CREATE PROCEDURE [dbo].[AddSiteSpecification]
(
	@EDISID 		INT,
	@CleanDaysBeforeAmber	INT = NULL,
	@CleanDaysBeforeRed		INT = NULL
)

AS

SET NOCOUNT ON

INSERT INTO dbo.SiteSpecifications
  (EDISID, CleanDaysBeforeAmber, CleanDaysBeforeRed)
VALUES
  (@EDISID, @CleanDaysBeforeAmber, @CleanDaysBeforeRed)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSiteSpecification] TO PUBLIC
    AS [dbo];

