
CREATE PROCEDURE dbo.UpdateSiteLastImportedEndDate
(
	@EDISID					INT = NULL,
	@LastImportedEndDate	DATETIME
)
AS

SET NOCOUNT ON

UPDATE Sites
SET LastImportedEndDate = @LastImportedEndDate
WHERE (EDISID = @EDISID OR @EDISID IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastImportedEndDate] TO PUBLIC
    AS [dbo];

