---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE UpdateCallSupplementaryStatus
(
	@CallID			INT,
	@StatusID		INT,
	@SupplementaryDate	DATETIME	= NULL,
	@SupplementaryText	VARCHAR(1024)	= NULL,
	@NewID			INT 	OUTPUT
)

AS

INSERT INTO SupplementaryCallStatusItems
(CallID, SupplementaryCallStatusID, SupplementaryDate, SupplementaryText)
VALUES
(@CallID, @StatusID, @SupplementaryDate, @SupplementaryText)

SET @NewID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallSupplementaryStatus] TO PUBLIC
    AS [dbo];

