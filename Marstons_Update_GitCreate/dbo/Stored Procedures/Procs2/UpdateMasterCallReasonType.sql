
CREATE PROCEDURE [dbo].[UpdateMasterCallReasonType]
(
	@CallReasonTypeID		INT,
	@Description			VARCHAR(1000),
	@Explanation			TEXT,
	@CategoryID				INT,
	@PriorityID				INT,
	@FlagToFinance			BIT,
	@DiagnosticID			INT,
	@SLA					INT = NULL,
	@ShowProducts			BIT,
	@AuthorisationRequired	BIT,
	@BMSEstimatedTime		FLOAT,
	@IDraughtEstimatedTime	FLOAT,
	@IsSystemTypeAffected	BIT,
	@AddToSystemStock		BIT,
	@GetFromSystemStock		BIT,
	@CheckIsKeyTap			BIT,
	@ExcludeFromQuality		BIT = 0,
	@ExcludeFromYield		BIT = 0,
	@ExcludeFromEquipment	BIT = 0,
	@ExcludeAllProducts		BIT = 0,
	@ShowEquipment			BIT = 0,
	@SLAForKeyTap			INT
)
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.UpdateCallReasonType @CallReasonTypeID,
															@Description,
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
															@ExcludeFromQuality,
															@ExcludeFromYield,
															@ExcludeFromEquipment,
															@ExcludeAllProducts,
															@ShowEquipment,
															@SLAForKeyTap


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateMasterCallReasonType] TO PUBLIC
    AS [dbo];

