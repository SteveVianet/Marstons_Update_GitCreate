CREATE PROCEDURE [dbo].[UpdateSiteBirthDate]
(
	@EDISID	INT,
	@BirthDate	DATETIME
)

AS

UPDATE Sites
SET BirthDate = @BirthDate
WHERE EDISID = @EDISID AND @BirthDate > '1990-01-01'

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteBirthDate] TO PUBLIC
    AS [dbo];

