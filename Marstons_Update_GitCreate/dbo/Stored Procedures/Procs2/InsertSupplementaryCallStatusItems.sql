---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[InsertSupplementaryCallStatusItems]
(
	@CallID						INT,
	@SupplementaryCallStatusID	INT,
	@SupplementaryDate			DATETIME,
	@SupplementaryText			VARCHAR(1024),
	@ChangedOn					DATETIME,
	@ChangedBy					VARCHAR(255)
)

AS

INSERT INTO SupplementaryCallStatusItems
	(CallID, SupplementaryCallStatusID, SupplementaryDate, SupplementaryText, ChangedOn, ChangedBy)
VALUES
	(@CallID, @SupplementaryCallStatusID, @SupplementaryDate, @SupplementaryText, @ChangedOn, @ChangedBy)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertSupplementaryCallStatusItems] TO PUBLIC
    AS [dbo];

