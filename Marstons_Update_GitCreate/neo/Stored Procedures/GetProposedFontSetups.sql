CREATE PROCEDURE [neo].[GetProposedFontSetups]
(
	@EDISID		INT	= NULL,
	@Completed	BIT	= NULL,
	@Available	BIT	= NULL
)

AS

SELECT	[ID],
	EDISID,
	CallID,
	dbo.GetCallReference(CallID) AS CallRef,
	UserName,
	CreateDate,
	Completed,
	Available,
	StockDelivered,
	StockDay,
	LineCleanDay,
	DispenseDataCleared,
	Comment,
	REPLACE(SUBSTRING(Calibrator,CHARINDEX('\',Calibrator)+1,LEN(Calibrator)), '.', ' ')AS Calibrator,
	FlowmetersUsed,
	TamperCapsUsed,
	PowerSupplyType,
	GlasswareStateID,
	CAMEngineerID
FROM dbo.ProposedFontSetups
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND (Completed = @Completed OR @Completed IS NULL)
AND (Available = @Available OR @Available IS NULL)
ORDER BY CreateDate DESC

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetProposedFontSetups] TO PUBLIC
    AS [dbo];

