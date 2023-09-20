CREATE PROCEDURE [dbo].[RemoveSerialNo]
(
	@EDISID 	INTEGER
)

AS

UPDATE dbo.Sites
SET SerialNo = ''
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RemoveSerialNo] TO PUBLIC
    AS [dbo];

