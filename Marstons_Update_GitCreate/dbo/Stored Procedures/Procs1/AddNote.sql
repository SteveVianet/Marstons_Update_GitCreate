---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE AddNote
(
	@EDISID			INT,
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
	@NewID			INT		OUTPUT
)

AS

INSERT INTO dbo.SiteNotes
(EDISID, BuyingOut, ActionID, OutcomeID, 
 BDMActionRequired, BDMActioned, 
 Undertaking, Injunction, Liquidated, Value, 
 TheVisit, 
 Discussions, Evidence, TradingPatterns, 
 FurtherDiscussions, BuyingOutLevel, CourseOfAction, 
 UserID, [Date], TrackingDate)
VALUES
(@EDISID, @BuyingOut, @ActionID, @OutcomeID, 
 @BDMActionRequired, @BDMActioned, 
 @Undertaking, @Injunction, @Liquidated, @Value, 
 @TheVisit, 
 @Discussions, @Evidence, @TradingPatterns, 
 @FurtherDiscussions, @BuyingOutLevel, @CourseOfAction, 
 @UserID, @VisitDate, @TrackingDate)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddNote] TO PUBLIC
    AS [dbo];

