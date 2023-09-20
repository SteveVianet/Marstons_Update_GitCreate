CREATE PROCEDURE [dbo].[UpdateEngineer]
(
	@EngineerID	INT,
	@Name		VARCHAR(255),
	@Mobile	VARCHAR(255),
	@Active	BIT,
	@LoginID	INT = NULL,
	@Address1	VARCHAR(255) = NULL,
	@Address2	VARCHAR(255) = NULL,
	@Address3	VARCHAR(255) = NULL,
	@Address4	VARCHAR(255) = NULL,
	@PostCode	VARCHAR(15) = NULL,
	@HandheldIMEI	VARCHAR(15) = NULL
)

AS

EXEC [SQL1\SQL1].ServiceLogger.dbo.UpdateEngineer @EngineerID,
						      @Name,
						      @Mobile,
						      @Active,
						      @LoginID,
						      @Address1,
						      @Address2,
						      @Address3,
						      @Address4,
						      @PostCode,
						      @HandheldIMEI
						      

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateEngineer] TO PUBLIC
    AS [dbo];

