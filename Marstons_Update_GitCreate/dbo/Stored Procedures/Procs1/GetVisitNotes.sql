---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetVisitNotes
(
	@EDISID		INT = NULL
)

AS

SELECT	[ID],
	BuyingOut,
	ActionID,
	OutcomeID,
	BDMActionRequired,
	BDMActioned,
	Undertaking,
	Injunction,
	Liquidated,
	Value,
 	TheVisit,
	Discussions,
	Evidence,
	TradingPatterns,
	FurtherDiscussions,
	BuyingOutLevel,
	CourseOfAction,
	UserID,
	[Date],
	BDMUserID,
	BDMComment,
	BDMDate,
	TrackingDate,
	Confirmed,
	RobustAction,
	Cleared,
	EDISID
FROM dbo.SiteNotes
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
ORDER BY [Date]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVisitNotes] TO PUBLIC
    AS [dbo];

