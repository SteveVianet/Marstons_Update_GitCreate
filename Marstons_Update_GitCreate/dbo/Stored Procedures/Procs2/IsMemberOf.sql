﻿CREATE PROCEDURE [dbo].[IsMemberOf]
(
	@Role		VARCHAR(255)
)

AS

IF IS_MEMBER('db_owner') = 1
	RETURN 1
ELSE IF IS_MEMBER(@Role) = 1
	RETURN 1
ELSE
	RETURN 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IsMemberOf] TO PUBLIC
    AS [dbo];

