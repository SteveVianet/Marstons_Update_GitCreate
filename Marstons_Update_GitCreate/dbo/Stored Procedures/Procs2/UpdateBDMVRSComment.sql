CREATE PROCEDURE [dbo].[UpdateBDMVRSComment]
(
	@VISITID			INT,
	@UserID 			INT,
	@BDMComment 		TEXT,
	@Actioned			BIT,
	@Injunction			BIT,
	@UTLLOU			BIT,
	@DamagesIssued		BIT,
	@DamagesIssuedValue	MONEY
)

AS

UPDATE dbo.VisitRecords
SET BDMID = @UserID,
BDMCommentDate = GETDATE(),
BDMComment = @BDMComment,
Actioned = @Actioned,
Injunction = @Injunction,
BDMUTLLOU = @UTLLOU,
BDMDamagesIssued = @DamagesIssued,
BDMDamagesIssuedValue = @DamagesIssuedValue
WHERE [ID] = @VISITID
AND Deleted = 0
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateBDMVRSComment] TO PUBLIC
    AS [dbo];

