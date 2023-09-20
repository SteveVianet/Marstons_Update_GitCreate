---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddContractor
(
	@Name			VARCHAR(255),
	@Telephone		VARCHAR(255),
	@Mobile			VARCHAR(255),
	@Fax			VARCHAR(255),
	@Address1		VARCHAR(255),
	@Address2		VARCHAR(255),
	@Address3		VARCHAR(255),
	@Address4		VARCHAR(255),
	@Postcode		VARCHAR(25),
	@EMail			VARCHAR(512),
	@Comment		VARCHAR(1024)
)

AS

DECLARE @NewContractorID INT

EXEC @NewContractorID = [SQL1\SQL1].ServiceLogger.dbo.AddContractor @Name,
									@Telephone,
									@Mobile,
									@Fax,
									@Address1,
									@Address2,
									@Address3,
									@Address4,
									@Postcode,
									@EMail,
									@Comment

RETURN @NewContractorID



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddContractor] TO PUBLIC
    AS [dbo];

