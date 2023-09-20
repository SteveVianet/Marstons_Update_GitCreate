---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddPropertyType
(
	@PropertyName	VARCHAR(50),
	@NewID	INT OUTPUT
)

AS

INSERT INTO dbo.Properties
([Name])
VALUES
(@PropertyName)

SET @NewID = @@IDENTITY


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPropertyType] TO PUBLIC
    AS [dbo];

