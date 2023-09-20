CREATE PROCEDURE [dbo].[ReOpenVisitRecord]
	-- Add the parameters for the stored procedure here
(
	
	@VisitNoteID INT
	
)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE VisitRecords
	
	SET BDMID = NULL,
		BDMCommentDate = NULL,
		BDMComment = NULL,
		BDMDamagesIssued = 0,
		BDMDamagesIssuedValue = 0,
		CompletedByCustomer= NULL,
		CompletedDate = NULL,
		BDMActionTaken = NULL,
		BDMPartialReason = NULL,
		VerifiedByVRS = NULL, 
		VerifiedDate = NULL
	
	WHERE [ID] = @VisitNoteID
	AND Deleted = 0
		
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ReOpenVisitRecord] TO PUBLIC
    AS [dbo];

