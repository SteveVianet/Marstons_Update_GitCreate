---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[SetGlobalEDISID]
(
	@EDISID		INT,
	@GlobalEDISID	INT
)

AS

UPDATE Sites
SET GlobalEDISID = @GlobalEDISID
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SetGlobalEDISID] TO PUBLIC
    AS [dbo];

