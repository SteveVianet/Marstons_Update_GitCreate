﻿CREATE PROCEDURE [dbo].[RemoveEDISTelNo]
(
	@EDISID 	INTEGER
)

AS

UPDATE dbo.Sites
SET EDISTelNo = ''
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RemoveEDISTelNo] TO PUBLIC
    AS [dbo];
