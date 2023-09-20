CREATE PROCEDURE [dbo].[CheckSerialNumber]
(
	@SerialNumber		VARCHAR(50)
)
AS

EXEC [EDISSQL1\SQL1].Auditing.dbo.CheckSerialNumber @SerialNumber


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CheckSerialNumber] TO PUBLIC
    AS [dbo];

