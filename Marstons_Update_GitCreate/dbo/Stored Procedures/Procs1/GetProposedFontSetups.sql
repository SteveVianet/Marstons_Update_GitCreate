CREATE PROCEDURE [dbo].[GetProposedFontSetups]
(
	@EDISID		INT	= NULL,
	@Completed	BIT	= NULL,
	@Available	BIT	= NULL
)

AS

SELECT	[ID],
	EDISID,
	CallID,
	UserName,
	CreateDate,
	Completed,
	Available,
	StockDelivered,
	StockDay,
	LineCleanDay,
	DispenseDataCleared,
	Comment,
	Calibrator,
	FlowmetersUsed,
	TamperCapsUsed,
	PowerSupplyType,
	GlasswareStateID,
	CAMEngineerID
FROM dbo.ProposedFontSetups
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND (Completed = @Completed OR @Completed IS NULL)
AND (Available = @Available OR @Available IS NULL)
ORDER BY CreateDate



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProposedFontSetups] TO PUBLIC
    AS [dbo];

