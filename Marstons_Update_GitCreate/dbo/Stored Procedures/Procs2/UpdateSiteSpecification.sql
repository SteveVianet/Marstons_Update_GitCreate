
CREATE PROCEDURE [dbo].[UpdateSiteSpecification] 
(
	@EDISID					INT,
    @CleanDaysBeforeAmber	INT,
    @CleanDaysBeforeRed		INT
)

AS

SET NOCOUNT ON

UPDATE dbo.SiteSpecifications
SET	CleanDaysBeforeAmber = @CleanDaysBeforeAmber,
	CleanDaysBeforeRed = @CleanDaysBeforeRed	
WHERE [EDISID] = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteSpecification] TO PUBLIC
    AS [dbo];

