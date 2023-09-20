---------------------------------------------------------------------------
--
--  Procedure Header
--
---------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[InsertNote]
(
	@EDISID				INT,
    @BuyingOut			BIT,
    @ActionID			INT,
    @OutcomeID			INT,
    @BDMActionRequired	BIT,
    @BDMActioned		BIT,
    @Undertaking		BIT,
    @Injunction			BIT,
    @Liquidated			BIT,
    @Value				FLOAT,
    @TheVisit			TEXT,
    @Discussions		TEXT,
    @Evidence			TEXT,
    @TradingPatterns	TEXT,
    @FurtherDiscussions	TEXT,
    @BuyingOutLevel		TEXT,
    @CourseOfAction		TEXT,
    @UserID				INT,
    @VisitDate			DATETIME,
	@TrackingDate		DATETIME,
	@NewID				INT		OUTPUT,
	@BDMUserID			INT = NULL,
	@BDMComment			TEXT = NULL,
	@BDMDate			DATETIME = NULL,
	@Confirmed			BIT = NULL,
	@RobustAction		BIT,
	@Cleared			BIT
)

AS

INSERT INTO dbo.SiteNotes
(EDISID, BuyingOut, ActionID, OutcomeID, BDMActionRequired, BDMActioned, 
 Undertaking, Injunction, Liquidated, Value, TheVisit, 
 Discussions, Evidence, TradingPatterns, FurtherDiscussions, BuyingOutLevel, CourseOfAction, 
 UserID, [Date], TrackingDate, BDMUserID, BDMComment, BDMDate, Confirmed, RobustAction, Cleared)
VALUES
(@EDISID, @BuyingOut, @ActionID, @OutcomeID, @BDMActionRequired, @BDMActioned, 
 @Undertaking, @Injunction, @Liquidated, @Value, @TheVisit, 
 @Discussions, @Evidence, @TradingPatterns, @FurtherDiscussions, @BuyingOutLevel, @CourseOfAction, 
 @UserID, @VisitDate, @TrackingDate, @BDMUserID, @BDMComment, @BDMDate, @Confirmed, @RobustAction, @Cleared)

SET @NewID = @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[InsertNote] TO PUBLIC
    AS [dbo];

