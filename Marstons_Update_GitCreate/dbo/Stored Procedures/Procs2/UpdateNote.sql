CREATE PROCEDURE UpdateNote
(
	@NoteID			INT,
        @BuyingOut		BIT,
        @ActionID		INT,
        @OutcomeID		INT,
        @BDMActionRequired	BIT,
        @BDMActioned		BIT,
        @Undertaking		BIT,
        @Injunction		BIT,
        @Liquidated		BIT,
        @Value			FLOAT,
        @TheVisit		TEXT,
        @Discussions		TEXT,
        @Evidence		TEXT,
        @TradingPatterns	TEXT,
        @FurtherDiscussions	TEXT,
        @BuyingOutLevel		TEXT,
        @CourseOfAction		TEXT,
        @UserID			INT,
        @VisitDate		DATETIME,
        @TrackingDate		DATETIME,
        @BDMComment		TEXT = NULL
)

AS

UPDATE dbo.SiteNotes
SET	BuyingOut = @BuyingOut,
	ActionID = @ActionID,
	OutcomeID = @OutcomeID,
	BDMActionRequired = @BDMActionRequired,
	BDMActioned = @BDMActioned,
	Undertaking = @Undertaking,
	Injunction = @Injunction,
	Liquidated = @Liquidated,
	Value = @Value,
	TheVisit = @TheVisit,
	Discussions = @Discussions,
	Evidence = @Evidence,
	TradingPatterns = @TradingPatterns,
	FurtherDiscussions = @FurtherDiscussions,
	BuyingOutLevel = @BuyingOutLevel,
	CourseOfAction = @CourseOfAction,
	UserID = @UserID,
	[Date] = @VisitDate,
	TrackingDate = @TrackingDate,
	BDMComment = @BDMComment
WHERE [ID] = @NoteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateNote] TO PUBLIC
    AS [dbo];

