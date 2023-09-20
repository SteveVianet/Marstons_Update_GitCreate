CREATE PROCEDURE [dbo].[AddCallReasonType]
(
	@Description	VARCHAR(1000),
	@Explanation	VARCHAR(8000) = '',
	@CategoryID		INT = 1,
	@PriorityID		INT = 1,
	@FlagToFinance	BIT = 0,
	@DiagnosticID	INT = 1,
	@SLA			INT = 0,
	@ShowProducts	BIT = 0,
	@AuthorisationRequired	BIT = 0,
	@BMSEstimatedTime		FLOAT = 10,
	@IDraughtEstimatedTime	FLOAT = 10,
	@IsSystemTypeAffected	BIT = 0,
	@AddToSystemStock		BIT = 0,
	@GetFromSystemStock		BIT = 0,
	@CheckIsKeyTap			BIT = 0,
	@NewID					INT OUTPUT
)
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.AddCallReasonType @Description,
														 @Explanation,
														 @CategoryID,
														 @PriorityID,
														 @FlagToFinance,
														 @DiagnosticID,
														 @SLA,
														 @ShowProducts,
														 @AuthorisationRequired,
														 @BMSEstimatedTime,
														 @IDraughtEstimatedTime,
														 @IsSystemTypeAffected,
														 @AddToSystemStock,
														 @GetFromSystemStock,
														 @CheckIsKeyTap,
														 @NewID OUTPUT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallReasonType] TO PUBLIC
    AS [dbo];

