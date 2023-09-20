
CREATE PROCEDURE [dbo].[GetCallReasonTypes]
(
	@ContractID		INT = NULL
)
AS

SET NOCOUNT ON

IF @ContractID IS NULL
BEGIN
		SELECT ID,
		  [Description],
		  Explanation,
		  CategoryID,
		  PriorityID,
		  FlagToFinance,
		  DiagnosticID,
		  SLA,
		  ShowProducts,
		  AuthorisationRequired,
		  BMSEstimatedTime,
		  IDraughtEstimatedTime,
		  IsSystemTypeAffected,
		  AddToSystemStock,
		  GetFromSystemStock,
		  CheckIsKeyTap,
		  NULL AS ContractID,
		  ExcludeFromQuality,
		  ExcludeFromYield,
		  ExcludeFromEquipment,
		  ExcludeAllProducts,
		  ShowEquipment,
		  COALESCE(SLAForKeyTap,SLA) AS SLAForKeyTap
	FROM [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes
	ORDER BY [ID]
END
ELSE
BEGIN
	SELECT ID,
		  [Description],
		  Explanation,
		  CategoryID,
		  COALESCE(CallReasonTypes.PriorityID, GlobalCallReasonTypes.PriorityID) AS PriorityID,
		  COALESCE(CallReasonTypes.FlagToFinance, GlobalCallReasonTypes.FlagToFinance) AS FlagToFinance,
		  DiagnosticID,
		  COALESCE(CASE WHEN CallReasonTypes.SLA = 0 THEN NULL ELSE CallReasonTypes.SLA END, GlobalCallReasonTypes.SLA) AS SLA,
		  ShowProducts,
		  COALESCE(CallReasonTypes.AuthorisationRequired, GlobalCallReasonTypes.AuthorisationRequired) AS AuthorisationRequired,
		  BMSEstimatedTime,
		  IDraughtEstimatedTime,
		  IsSystemTypeAffected,
		  AddToSystemStock,
		  GetFromSystemStock,
		  CheckIsKeyTap,
		  @ContractID AS ContractID,
		  ExcludeFromQuality,
		  ExcludeFromYield,
		  ExcludeFromEquipment,
		  ExcludeAllProducts,
		  ShowEquipment,
		  COALESCE(CallReasonTypes.SLAForKeyTap, GlobalCallReasonTypes.SLAForKeyTap, CallReasonTypes.SLA, GlobalCallReasonTypes.SLA) AS SLAForKeyTap
	FROM [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes
	LEFT JOIN CallReasonTypes ON CallReasonTypes.CallReasonTypeID = GlobalCallReasonTypes.[ID] AND (ContractID = @ContractID OR @ContractID IS NULL)
	ORDER BY [ID]

END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCallReasonTypes] TO PUBLIC
    AS [dbo];

