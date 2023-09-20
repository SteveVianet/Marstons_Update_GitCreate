---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetSupplementaryCallStatusItems]
(
	@CallID			INT
)

AS

SELECT CallID, SupplementaryCallStatusID, SupplementaryDate, SupplementaryText, ChangedOn, ChangedBy
FROM SupplementaryCallStatusItems
WHERE CallID = @CallID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSupplementaryCallStatusItems] TO PUBLIC
    AS [dbo];

