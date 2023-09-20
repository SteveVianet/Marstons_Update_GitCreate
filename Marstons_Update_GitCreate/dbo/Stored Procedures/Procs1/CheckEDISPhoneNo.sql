CREATE PROCEDURE [dbo].[CheckEDISPhoneNo]
(
	@PhoneNumber		VARCHAR(50)
)
AS

EXEC [EDISSQL1\SQL1].PhoneBill.dbo.CheckEDISPhoneNo @PhoneNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CheckEDISPhoneNo] TO PUBLIC
    AS [dbo];

