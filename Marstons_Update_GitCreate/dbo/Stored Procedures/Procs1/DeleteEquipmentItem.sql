CREATE PROCEDURE [dbo].[DeleteEquipmentItem]
(
	@EDISID 			INT, 
	@SlaveID			INT = NULL,
	@IsDigital			BIT = NULL,
	@InputID			INT,
	@Permanent			BIT = 0
)

AS

SET NOCOUNT ON

IF @Permanent = 1
BEGIN
	DELETE FROM dbo.EquipmentItems
	WHERE InputID = @InputID
	AND EDISID = @EDISID
END
ELSE
BEGIN
	-- Just mark as not in use
	UPDATE dbo.EquipmentItems
	SET InUse = 0
	WHERE InputID = @InputID
	AND EDISID = @EDISID
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DeleteEquipmentItem] TO PUBLIC
    AS [dbo];

