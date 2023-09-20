---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE GetOutstandingVisitNotes

AS

SELECT	EDISID,
	[ID],
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
	Cleared
FROM dbo.SiteNotes
WHERE BDMActionRequired = 1
AND BDMActioned = 0
ORDER BY EDISID, [Date]
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetOutstandingVisitNotes] TO PUBLIC
    AS [dbo];

