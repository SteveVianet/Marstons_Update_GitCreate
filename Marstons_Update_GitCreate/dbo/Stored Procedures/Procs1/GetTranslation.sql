
---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetTranslation
(
	@ActualName VARCHAR(255)
)

AS

SELECT TranslatedName
FROM Translations
WHERE ActualName = @ActualName


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetTranslation] TO PUBLIC
    AS [dbo];

